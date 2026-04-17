import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/scanned_document.dart';
import '../providers/document_scanner_provider.dart';
import 'document_viewer_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DocumentScannerScreen
// ─────────────────────────────────────────────────────────────────────────────

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _isScanning = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<DocumentScannerProvider>();
    final docs = provider.filteredDocuments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHighest : cs.primary,
        foregroundColor: isDark ? cs.onSurface : Colors.white,
        elevation: 0,
        title: const Text(
          'Document Scanner',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          if (provider.selectedCategory != null || provider.searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                provider.clearFilters();
                _searchController.clear();
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => provider.setSearchQuery(q),
          ),
          _CategoryFilterRow(provider: provider),
          Expanded(
            child: docs.isEmpty
                ? _EmptyState(
                    isFiltered: provider.selectedCategory != null ||
                        provider.searchQuery.isNotEmpty,
                  )
                : _DocumentGrid(docs: docs),
          ),
        ],
      ),
      floatingActionButton: _ScanFAB(
        isScanning: _isScanning,
        onScanCamera: () => _startScan(context, fromCamera: true),
        onScanGallery: () => _startScan(context, fromCamera: false),
      ),
    );
  }

  // ── Scan flow ───────────────────────────────────────────────────────────────

  Future<void> _startScan(BuildContext context, {required bool fromCamera}) async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      final provider = context.read<DocumentScannerProvider>();
      final path = await provider.scanDocument(fromCamera: fromCamera);

      if (!mounted) return;

      if (path == null) {
        // null = cancelled OR permission denied → show snackbar
        _showPermissionDeniedMessage(context, fromCamera: fromCamera);
        return;
      }

      // Ask user for a title
      final title = await _showTitleDialog(context);
      if (!mounted) return;

      final now = DateTime.now();
      final doc = ScannedDocument(
        id: const Uuid().v4(),
        title: title?.isNotEmpty == true ? title! : _generateTitle(now),
        filePath: path,
        createdAt: now,
        updatedAt: now,
        categories: [],
      );

      await provider.addDocument(doc);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(document: doc),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DocScannerScreen] _startScan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showPermissionDeniedMessage(BuildContext context, {required bool fromCamera}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fromCamera
              ? 'Camera permission is required. Please allow it in Settings.'
              : 'Photo access is required. Please allow it in Settings.',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<String?> _showTitleDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this document'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Contract, Invoice…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateTitle(DateTime dt) =>
      'Document ${DateFormat('MMM d, yyyy HH:mm').format(dt)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search documents…',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filter Chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  final DocumentScannerProvider provider;
  const _CategoryFilterRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = provider.allCategories;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return ActionChip(
              avatar: Icon(Icons.add_rounded, size: 16, color: cs.primary),
              label: const Text('New Tag'),
              onPressed: () => _showAddCategoryDialog(context),
            );
          }
          final cat = categories[index];
          final isSelected = provider.selectedCategory == cat;
          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => provider.setSelectedCategory(cat),
            selectedColor: cs.primaryContainer,
            checkmarkColor: cs.onPrimaryContainer,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Medical, Travel…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) provider.addCustomCategory(v.trim());
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.addCustomCategory(ctrl.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Grid
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentGrid extends StatelessWidget {
  final List<ScannedDocument> docs;
  const _DocumentGrid({required this.docs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: docs.length,
      itemBuilder: (context, i) => _DocumentCard(doc: docs[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Card
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final ScannedDocument doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(document: doc),
        ),
      ),
      child: Card(
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cs.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _DocumentThumbnail(filePath: doc.filePath)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(doc.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (doc.categories.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: doc.categories.take(3).map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                cs.primaryContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentThumbnail extends StatelessWidget {
  final String filePath;
  const _DocumentThumbnail({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<bool>(
      future: File(filePath).exists(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.file(
            File(filePath),
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _placeholder(cs),
          );
        }
        return _placeholder(cs);
      },
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.description_rounded,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.document_scanner_rounded,
              size: 72,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No documents match' : 'No documents yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try clearing the filter or search.'
                  : 'Tap the scan button below\nto capture your first document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan FAB
// ─────────────────────────────────────────────────────────────────────────────

class _ScanFAB extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScanCamera;
  final VoidCallback onScanGallery;

  const _ScanFAB({
    required this.isScanning,
    required this.onScanCamera,
    required this.onScanGallery,
  });

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return FloatingActionButton(
        onPressed: null,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_gallery',
          onPressed: onScanGallery,
          tooltip: 'Import from Gallery',
          child: const Icon(Icons.photo_library_rounded),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'fab_camera',
          onPressed: onScanCamera,
          icon: const Icon(Icons.document_scanner_rounded),
          label: const Text('Scan Document'),
        ),
      ],
    );
  }
}
