import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// نموذج بيانات سطر واحد في الصفحة
class QuranLine {
  final int lineNumber;
  final String lineType; // 'ayah' | 'surah_name' | 'basmallah'
  final bool isCentered;
  final String text; // الكلمات مجمعة
  final int? surahNumber; // موجود فقط في surah_name
  final List<QuranWord> words;

  const QuranLine({
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.text,
    this.surahNumber,
    required this.words,
  });
}

/// نموذج كلمة واحدة مع بياناتها
class QuranWord {
  final int id;
  final int surah;
  final int ayah;
  final int wordIndex;
  final String text;

  const QuranWord({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.text,
  });
}

class QuranDatabaseService {
  static Database? _wordsDb;
  static Database? _pagesDb;

  // Cache للصفحات المحملة
  static final Map<int, List<QuranLine>> _pageCache = {};

  /// تهيئة قواعد البيانات
  static Future<void> init() async {
    if (_wordsDb != null && _pagesDb != null) return;

    final dbPath = await getDatabasesPath();

    // نسخ qpc-v2.db
    final wordsPath = join(dbPath, 'qpc-v2.db');
    if (!await File(wordsPath).exists()) {
      final data = await rootBundle.load('assets/db/qpc-v2.db');
      await File(wordsPath).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }

    // نسخ qpc-v2-15-lines.db
    final pagesPath = join(dbPath, 'qpc-v2-15-lines.db');
    if (!await File(pagesPath).exists()) {
      final data = await rootBundle.load('assets/db/qpc-v2-15-lines.db');
      await File(pagesPath).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }

    _wordsDb = await openDatabase(wordsPath, readOnly: true);
    _pagesDb = await openDatabase(pagesPath, readOnly: true);
  }

  /// جيب بيانات صفحة كاملة (سطر سطر) - استعلام واحد فقط لكل الكلمات
  static Future<List<QuranLine>> getPageLines(int pageNumber) async {
    // من الكاش لو موجودة
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    await init();

    // جيب سطور الصفحة
    final lineRows = await _pagesDb!.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    // حدد أصغر وأكبر word_id في الصفحة كلها (استعلام واحد بس)
    int? minId;
    int? maxId;

    for (final lineRow in lineRows) {
      final firstWordId = lineRow['first_word_id'];
      final lastWordId = lineRow['last_word_id'];
      if (firstWordId == null ||
          lastWordId == null ||
          firstWordId.toString().isEmpty ||
          lastWordId.toString().isEmpty) {
        continue;
      }
      final first = int.parse(firstWordId.toString());
      final last = int.parse(lastWordId.toString());
      if (minId == null || first < minId) minId = first;
      if (maxId == null || last > maxId) maxId = last;
    }

    // جيب كل كلمات الصفحة بستعلام واحد فقط
    Map<int, QuranWord> wordsById = {};
    if (minId != null && maxId != null) {
      final wordRows = await _wordsDb!.query(
        'words',
        where: 'id >= ? AND id <= ?',
        whereArgs: [minId, maxId],
        orderBy: 'id ASC',
      );

      for (final w in wordRows) {
        final id = w['id'] as int;
        wordsById[id] = QuranWord(
          id: id,
          surah: w['surah'] as int,
          ayah: w['ayah'] as int,
          wordIndex: w['word'] as int,
          text: w['text'] as String,
        );
      }
    }

    final List<QuranLine> lines = [];

    for (final lineRow in lineRows) {
      final lineType = lineRow['line_type'] as String;
      final lineNumber = lineRow['line_number'] as int;
      final isCentered = (lineRow['is_centered'] as int) == 1;
      final firstWordId = lineRow['first_word_id'];
      final lastWordId = lineRow['last_word_id'];
      final surahNum = lineRow['surah_number'];

      // سطر اسم السورة أو البسملة - مفيش كلمات
      if (lineType == 'surah_name' || lineType == 'basmallah') {
        lines.add(QuranLine(
          lineNumber: lineNumber,
          lineType: lineType,
          isCentered: true,
          text: '',
          surahNumber: surahNum != null && surahNum.toString().isNotEmpty
              ? int.tryParse(surahNum.toString())
              : null,
          words: const [],
        ));
        continue;
      }

      // سطر آيات
      if (firstWordId == null ||
          lastWordId == null ||
          firstWordId.toString().isEmpty ||
          lastWordId.toString().isEmpty) {
        continue;
      }

      final int first = int.parse(firstWordId.toString());
      final int last = int.parse(lastWordId.toString());

      final List<QuranWord> words = [];
      for (int id = first; id <= last; id++) {
        final w = wordsById[id];
        if (w != null) words.add(w);
      }

      lines.add(QuranLine(
        lineNumber: lineNumber,
        lineType: lineType,
        isCentered: isCentered,
        text: '',
        words: words,
      ));
    }

    _pageCache[pageNumber] = lines;
    return lines;
  }

  /// تحميل صفحة مسبقاً في الخلفية (بدون انتظار النتيجة)
  static void preloadPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) return;
    if (_pageCache.containsKey(pageNumber)) return;
    getPageLines(pageNumber);
  }

  /// امسح الكاش (لو احتجت)
  static void clearCache() => _pageCache.clear();

  static Future<void> close() async {
    await _wordsDb?.close();
    await _pagesDb?.close();
    _wordsDb = null;
    _pagesDb = null;
  }
}