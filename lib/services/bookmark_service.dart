import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/bookmark_model.dart';
import '../utils/quran_constants.dart';

class BookmarkService {
  late Box<dynamic> _bookmarksBox;
  late Box<dynamic> _progressBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _bookmarksBox = await Hive.openBox(QuranConstants.bookmarksBoxName);
    _progressBox =
        await Hive.openBox(QuranConstants.readingProgressBoxName);
    _isInitialized = true;
  }

  // Add bookmark
  Future<Bookmark> addBookmark({
    required int surahNumber,
    required int ayahNumber,
    required int pageNumber,
    String? notes,
  }) async {
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
      createdAt: DateTime.now(),
      notes: notes,
    );

    await _bookmarksBox.put(bookmark.id, jsonEncode(bookmark.toJson()));
    return bookmark;
  }

  // Get all bookmarks
  Future<List<Bookmark>> getAllBookmarks() async {
    final bookmarks = <Bookmark>[];
    for (var key in _bookmarksBox.keys) {
      final data = _bookmarksBox.get(key);
      if (data != null) {
        bookmarks.add(Bookmark.fromJson(jsonDecode(data)));
      }
    }
    return bookmarks..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Delete bookmark
  Future<void> deleteBookmark(String id) async {
    await _bookmarksBox.delete(id);
  }

  // Update reading progress
  Future<void> updateReadingProgress({
    required int page,
    required int surah,
    required int ayah,
    required int juz,
  }) async {
    final progress = ReadingProgress(
      lastReadPage: page,
      lastReadSurah: surah,
      lastReadAyah: ayah,
      lastReadTime: DateTime.now(),
      totalPagesRead: (await _getLastProgress()?.totalPagesRead ?? 0) + 1,
      currentJuz: juz,
    );

    await _progressBox.put('current_progress', jsonEncode(progress.toJson()));
  }

  // Get reading progress
  Future<ReadingProgress?> getReadingProgress() async {
    final data = _progressBox.get('current_progress');
    if (data != null) {
      return ReadingProgress.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<ReadingProgress?> _getLastProgress() async {
    final data = _progressBox.get('current_progress');
    if (data != null) {
      return ReadingProgress.fromJson(jsonDecode(data));
    }
    return null;
  }

  void dispose() {
    _bookmarksBox.close();
    _progressBox.close();
  }
}
