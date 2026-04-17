import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/scanned_document.dart';
import '../providers/document_scanner_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DocumentViewerScreen
//
// Full-screen view of a scanned document with:
//   • Zoomable / pannable image preview
//   • Metadata panel (title, date, categories, notes)
//   • Rename, edit categories/notes, delete actions
// ─────────────────────────────────────────────────────────────────────────────

class DocumentViewerScreen extends StatefulWidget {
  final ScannedDocument document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late ScannedDocument _doc;
  bool _showInfo = false;
  bool _fileExists = true;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
    _checkFile();
  }

  Future<void> _checkFile() async {
    final exists = await context.read<DocumentScannerProvider>().fileExists(_doc.filePath);
    if (mounted) setState(() => _fileExists = exists);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _doc.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(_showInfo ? Icons.info : Icons.info_outline_rounded),
            tooltip: 'Document info',
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
          PopupMenuButton<_ViewerAction>(
            onSelected: (action) => _handleAction(context, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ViewerAction.rename,
                child: ListTile(
                  leading: Icon(Icons.drive_file_rename_outline_rounded),
                  title: Text('Rename'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _ViewerAction.editCategories,
                child: ListTile(
                  leading: Icon(Icons.label_rounded),
                  title: Text('Edit Categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _ViewerAction.editNotes,
                child: ListTile(
                  leading: Icon(Icons.notes_rounded),
                  title: Text('Edit Notes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ViewerAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_rounded, color: Colors.red[300]),
                  title: Text('Delete', style: TextStyle(color: Colors.red[300])),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image viewer
          Positioned.fill(child: _buildImageViewer(cs)),

          // Info panel
          if (_showInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _InfoPanel(doc: _doc),
            ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(ColorScheme cs) {
    if (!_fileExists) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.white38, size: 72),
            const SizedBox(height: 16),
            const Text(
              'File not found or was moved.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.file(
          File(_doc.filePath),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            _fileExists = false;
            return const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 72),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _ViewerAction action) async {
    final provider = context.read<DocumentScannerProvider>();

    switch (action) {
      case _ViewerAction.rename:
        final newTitle = await _showTextDialog(
          context,
          title: 'Rename Document',
          initialValue: _doc.title,
          hint: 'Enter new name',
        );
        if (newTitle != null && newTitle.isNotEmpty && mounted) {
          final updated = _doc.copyWith(title: newTitle);
          await provider.updateDocument(updated);
          setState(() => _doc = updated);
        }
        break;

      case _ViewerAction.editCategories:
        final updatedDoc = await _showCategoryEditor(context, provider);
        if (updatedDoc != null && mounted) {
          setState(() => _doc = updatedDoc);
        }
        break;

      case _ViewerAction.editNotes:
        final notes = await _showTextDialog(
          context,
          title: 'Edit Notes',
          initialValue: _doc.notes,
          hint: 'Add a note…',
          multiline: true,
        );
        if (notes != null && mounted) {
          final updated = _doc.copyWith(notes: notes);
          await provider.updateDocument(updated);
          setState(() => _doc = updated);
        }
        break;

      case _ViewerAction.delete:
        final confirmed = await _showDeleteDialog(context);
        if (confirmed == true && mounted) {
          await provider.deleteDocument(_doc);
          if (mounted) Navigator.of(context).pop();
        }
        break;
    }
  }

  Future<String?> _showTextDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hint,
    bool multiline = false,
  }) async {
    final ctrl = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: multiline ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<ScannedDocument?> _showCategoryEditor(
    BuildContext context,
    DocumentScannerProvider provider,
  ) async {
    final selected = List<String>.from(_doc.categories);
    final allCategories = provider.allCategories;

    return showModalBottomSheet<ScannedDocument>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditorSheet(
        allCategories: allCategories,
        selected: selected,
        provider: provider,
        onSave: (updatedCategories) async {
          final updated = _doc.copyWith(categories: updatedCategories);
          await provider.updateDocument(updated);
          Navigator.of(ctx).pop(updated);
        },
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${_doc.title}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

enum _ViewerAction { rename, editCategories, editNotes, delete }

// ─────────────────────────────────────────────────────────────────────────────
// Info Panel (bottom overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final ScannedDocument doc;
  const _InfoPanel({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            doc.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Created: ${DateFormat('MMMM d, yyyy · HH:mm').format(doc.createdAt)}',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
          ),

          if (doc.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: doc.categories.map((c) => Chip(
                label: Text(c, style: const TextStyle(fontSize: 11)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],

          if (doc.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              doc.notes,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Editor Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryEditorSheet extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selected;
  final DocumentScannerProvider provider;
  final Future<void> Function(List<String>) onSave;

  const _CategoryEditorSheet({
    required this.allCategories,
    required this.selected,
    required this.provider,
    required this.onSave,
  });

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late List<String> _selected;
  late List<String> _allCategories;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
    _allCategories = List.from(widget.allCategories);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Categories',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                  onPressed: _addNewCategory,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCategories.map((cat) {
                  final isSelected = _selected.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(cat);
                        } else {
                          _selected.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onSave(_selected),
                child: const Text('Save Categories'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name…',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_allCategories.contains(result)) {
      widget.provider.addCustomCategory(result);
      setState(() {
        _allCategories = List.from(widget.provider.allCategories);
        _selected.add(result);
      });
    }
  }
}
