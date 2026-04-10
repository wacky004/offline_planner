import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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

class BackupService {
  final DatabaseService _dbService;

  BackupService(this._dbService);

  // ─── EXPORT ───────────────────────────────────────────────────────────────

  Future<String?> exportBackup() async {
    try {
      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': 1,
        'entries': _dbService.getAllEntries().map(_entryToJson).toList(),
        'goals': _dbService.getAllGoals().map(_goalToJson).toList(),
        'recipes': _dbService.getAllRecipes().map(_recipeToJson).toList(),
        'bibleBooks': _dbService.getAllBibleBooks().map(_bibleBookToJson).toList(),
        'bibleChapters': _dbService.getAllBibleChapters().map(_bibleChapterToJson).toList(),
        'bibleVerses': _dbService.getAllBibleVerses().map(_bibleVerseToJson).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/planner_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  // ─── IMPORT ───────────────────────────────────────────────────────────────

  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final List entries = data['entries'] ?? [];
      final List goals = data['goals'] ?? [];
      final List recipes = data['recipes'] ?? [];
      final List bibleBooks = data['bibleBooks'] ?? [];
      final List bibleChapters = data['bibleChapters'] ?? [];
      final List bibleVerses = data['bibleVerses'] ?? [];

      for (var e in entries) {
        await _dbService.addEntry(_entryFromJson(e));
      }
      for (var g in goals) {
        await _dbService.addGoal(_goalFromJson(g));
      }
      for (var r in recipes) {
        await _dbService.addRecipe(_recipeFromJson(r));
      }
      for (var b in bibleBooks) {
        await _dbService.addBibleBook(_bibleBookFromJson(b));
      }
      for (var c in bibleChapters) {
        await _dbService.addBibleChapter(_bibleChapterFromJson(c));
      }
      for (var v in bibleVerses) {
        await _dbService.addBibleVerse(_bibleVerseFromJson(v));
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  // ─── SERIALIZERS ──────────────────────────────────────────────────────────

  Map<String, dynamic> _entryToJson(Entry e) => {
    'id': e.id,
    'type': e.type.index,
    'title': e.title,
    'notes': e.notes,
    'amount': e.amount,
    'date': e.date.toIso8601String(),
    'isCompletedOrPaid': e.isCompletedOrPaid,
    'hasReminder': e.hasReminder,
    'reminderTime': e.reminderTime?.toIso8601String(),
    'alarmSoundId': e.alarmSoundId,
    'updatedAt': e.updatedAt.toIso8601String(),
  };

  Entry _entryFromJson(Map<String, dynamic> m) => Entry(
    id: m['id'],
    type: EntryType.values[m['type']],
    title: m['title'],
    notes: m['notes'] ?? '',
    amount: m['amount'],
    date: DateTime.parse(m['date']),
    isCompletedOrPaid: m['isCompletedOrPaid'] ?? false,
    hasReminder: m['hasReminder'] ?? false,
    reminderTime: m['reminderTime'] != null ? DateTime.parse(m['reminderTime']) : null,
    alarmSoundId: m['alarmSoundId'],
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _goalToJson(Goal g) => {
    'id': g.id,
    'title': g.title,
    'targetAmount': g.targetAmount,
    'currentAmount': g.currentAmount,
    'updatedAt': g.updatedAt.toIso8601String(),
  };

  Goal _goalFromJson(Map<String, dynamic> m) => Goal(
    id: m['id'],
    title: m['title'],
    targetAmount: m['targetAmount'],
    currentAmount: m['currentAmount'] ?? 0.0,
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _recipeToJson(Recipe r) => {
    'id': r.id,
    'title': r.title,
    'ingredients': r.ingredients,
    'cookingSteps': r.cookingSteps,
    'category': r.category.index,
    'estimatedCost': r.estimatedCost,
    'notes': r.notes,
    'isFavorite': r.isFavorite,
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
    'imagePath': r.imagePath,
    'tags': r.tags,
  };

  Recipe _recipeFromJson(Map<String, dynamic> m) => Recipe(
    id: m['id'],
    title: m['title'],
    ingredients: m['ingredients'],
    cookingSteps: m['cookingSteps'],
    category: RecipeCategory.values[m['category']],
    estimatedCost: m['estimatedCost'],
    notes: m['notes'] ?? '',
    isFavorite: m['isFavorite'] ?? false,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
    imagePath: m['imagePath'],
    tags: List<String>.from(m['tags'] ?? []),
  );

  Map<String, dynamic> _bibleBookToJson(BibleBook b) => {
    'id': b.id,
    'name': b.name,
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt.toIso8601String(),
  };

  BibleBook _bibleBookFromJson(Map<String, dynamic> m) => BibleBook(
    id: m['id'],
    name: m['name'],
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _bibleChapterToJson(BibleChapter c) => {
    'id': c.id,
    'bookId': c.bookId,
    'chapterTitle': c.chapterTitle,
    'createdAt': c.createdAt.toIso8601String(),
    'updatedAt': c.updatedAt.toIso8601String(),
  };

  BibleChapter _bibleChapterFromJson(Map<String, dynamic> m) => BibleChapter(
    id: m['id'],
    bookId: m['bookId'],
    chapterTitle: m['chapterTitle'],
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _bibleVerseToJson(BibleVerse v) => {
    'id': v.id,
    'bookId': v.bookId,
    'chapterId': v.chapterId,
    'verseNumber': v.verseNumber,
    'verseText': v.verseText,
    'note': v.note,
    'isFavorite': v.isFavorite,
    'createdAt': v.createdAt.toIso8601String(),
    'updatedAt': v.updatedAt.toIso8601String(),
  };

  BibleVerse _bibleVerseFromJson(Map<String, dynamic> m) => BibleVerse(
    id: m['id'],
    bookId: m['bookId'],
    chapterId: m['chapterId'],
    verseNumber: m['verseNumber'],
    verseText: m['verseText'],
    note: m['note'] ?? '',
    isFavorite: m['isFavorite'] ?? false,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );
}
