import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../models/goal.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import 'database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MergeService
//
// Pure stateless merge logic.
//
// Merge rules:
//   • Insert records that do not exist locally.
//   • If the same id exists, keep the version with the latest updatedAt.
//   • Respect isDeleted flag — delete local record if remote marks it deleted.
//   • Never silently lose newer local data.
// ─────────────────────────────────────────────────────────────────────────────

class MergeService {
  MergeService._(); // Prevent instantiation — all methods are static.

  /// Parses [jsonStr] and merges every collection into [db].
  /// Throws [FormatException] on invalid JSON.
  static Future<void> mergeFromJson(
    String jsonStr,
    DatabaseService db,
  ) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('MergeService: malformed backup JSON — $e');
    }

    await mergeEntries(List.from(data['entries'] ?? []), db);
    await mergeGoals(List.from(data['goals'] ?? []), db);
    await mergeRecipes(List.from(data['recipes'] ?? []), db);
    await mergeBibleBooks(List.from(data['bibleBooks'] ?? []), db);
    await mergeBibleChapters(List.from(data['bibleChapters'] ?? []), db);
    await mergeBibleVerses(List.from(data['bibleVerses'] ?? []), db);
  }

  // ── Entries ───────────────────────────────────────────────────────────────

  static Future<void> mergeEntries(List incoming, DatabaseService db) async {
    final local = {for (final e in db.getAllEntries()) e.id: e};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteEntry(m['id'] as String);
        continue;
      }
      final remote = _entryFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addEntry(remote);
        debugPrint('[MergeService] Added new entry: ${remote.id}');
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateEntry(remote);
        debugPrint('[MergeService] Updated entry (remote newer): ${remote.id}');
      }
    }
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<void> mergeGoals(List incoming, DatabaseService db) async {
    final local = {for (final g in db.getAllGoals()) g.id: g};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteGoal(m['id'] as String);
        continue;
      }
      final remote = _goalFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addGoal(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateGoal(remote);
      }
    }
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  static Future<void> mergeRecipes(List incoming, DatabaseService db) async {
    final local = {for (final r in db.getAllRecipes()) r.id: r};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteRecipe(m['id'] as String);
        continue;
      }
      final remote = _recipeFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addRecipe(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateRecipe(remote);
      }
    }
  }

  // ── Bible Books ───────────────────────────────────────────────────────────

  static Future<void> mergeBibleBooks(
      List incoming, DatabaseService db) async {
    final local = {for (final b in db.getAllBibleBooks()) b.id: b};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteBibleBook(m['id'] as String);
        continue;
      }
      final remote = _bibleBookFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addBibleBook(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateBibleBook(remote);
      }
    }
  }

  // ── Bible Chapters ────────────────────────────────────────────────────────

  static Future<void> mergeBibleChapters(
      List incoming, DatabaseService db) async {
    final local = {for (final c in db.getAllBibleChapters()) c.id: c};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteBibleChapter(m['id'] as String);
        continue;
      }
      final remote = _bibleChapterFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addBibleChapter(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateBibleChapter(remote);
      }
    }
  }

  // ── Bible Verses ──────────────────────────────────────────────────────────

  static Future<void> mergeBibleVerses(
      List incoming, DatabaseService db) async {
    final local = {for (final v in db.getAllBibleVerses()) v.id: v};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await db.deleteBibleVerse(m['id'] as String);
        continue;
      }
      final remote = _bibleVerseFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await db.addBibleVerse(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await db.updateBibleVerse(remote);
      }
    }
  }

  // ── JSON deserializers ────────────────────────────────────────────────────

  static Entry _entryFromJson(Map<String, dynamic> m) => Entry(
        id: m['id'] as String,
        type: EntryType.values[m['type'] as int],
        title: m['title'] as String,
        notes: m['notes'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble(),
        date: DateTime.parse(m['date'] as String),
        isCompletedOrPaid: m['isCompletedOrPaid'] as bool? ?? false,
        hasReminder: m['hasReminder'] as bool? ?? false,
        reminderTime: m['reminderTime'] != null
            ? DateTime.parse(m['reminderTime'] as String)
            : null,
        alarmSoundId: m['alarmSoundId'] as String?,
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );

  static Goal _goalFromJson(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        title: m['title'] as String,
        targetAmount: (m['targetAmount'] as num).toDouble(),
        currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0.0,
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );

  static Recipe _recipeFromJson(Map<String, dynamic> m) => Recipe(
        id: m['id'] as String,
        title: m['title'] as String,
        ingredients: m['ingredients'] as String,
        cookingSteps: m['cookingSteps'] as String,
        category: RecipeCategory.values[m['category'] as int],
        estimatedCost: (m['estimatedCost'] as num?)?.toDouble(),
        notes: m['notes'] as String? ?? '',
        isFavorite: m['isFavorite'] as bool? ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
        imagePath: m['imagePath'] as String?,
        tags: List<String>.from(m['tags'] as List? ?? []),
      );

  static BibleBook _bibleBookFromJson(Map<String, dynamic> m) => BibleBook(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );

  static BibleChapter _bibleChapterFromJson(Map<String, dynamic> m) =>
      BibleChapter(
        id: m['id'] as String,
        bookId: m['bookId'] as String,
        chapterTitle: m['chapterTitle'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );

  static BibleVerse _bibleVerseFromJson(Map<String, dynamic> m) => BibleVerse(
        id: m['id'] as String,
        bookId: m['bookId'] as String,
        chapterId: m['chapterId'] as String,
        verseNumber: m['verseNumber'] as int,
        verseText: m['verseText'] as String,
        note: m['note'] as String? ?? '',
        isFavorite: m['isFavorite'] as bool? ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );
}
