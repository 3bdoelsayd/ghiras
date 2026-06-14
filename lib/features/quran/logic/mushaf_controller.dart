import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../data/quran_text.dart';
import '../data/translations/muyassar.dart';
import '../../../core/constants/app_colors.dart';

class MushafController extends GetxController {
  var currentPage = 1.obs;
  var fontSize = 28.0.obs;
  var isDarkMode = false.obs;
  
  // علامة الوقوف (الآية المحفوظة)
  var bookmarkedSurah = 0.obs;
  var bookmarkedAyah = 0.obs;
  
  // الفواصل (عناوين لصفحات معينة)
  var fawasil = <Map<String, dynamic>>[].obs;
  
  // العلامات الملونة (Ayah Bookmarks) - مأخوذ من كودك
  var ayahBookmarks = <Map<String, dynamic>>[].obs;
  
  // الآيات المفضلة (Starred Verses) - مستوحى من الكود المرسل
  var starredVerses = <String>{}.obs;

  // الآية المختارة حالياً عند الضغط المطول
  var selectedAyahKey = ''.obs;

  // تخزين ثابت للبيانات لعدم تكرار الحسابات
  static final Map<int, List<Map<String, dynamic>>> _pagesCache = {};
  static final Map<int, List<int>> _pageIndexMap = {};
  static final Map<String, String> _tafseerMap = {};
  static bool _isReady = false;

  var isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBookmark();
    _loadFawasil();
    _loadAyahBookmarks();
    _loadStarredVerses();
    
    // تشغيل العمليات الثقيلة في الخلفية لتجنب تعليق الواجهة
    _initDataAsync();
  }

  Future<void> _initDataAsync() async {
    if (_isReady) {
      isReady.value = true;
      return;
    }

    // انتظر قليلاً للسماح للشاشة بالظهور أولاً
    await Future.delayed(const Duration(milliseconds: 500));
    
    // فهرسة ذكية سريعة جداً
    await _initIndexingAsync();
    
    // تحميل التفسير بشكل متقطع لتوفير المعالج
    await _initTafseerAsync();

    _isReady = true;
    isReady.value = true;
  }

  Future<void> _initIndexingAsync() async {
    // إذا كانت البيانات مفهرسة مسبقاً لا نكرر العملية
    if (_pageIndexMap.isNotEmpty) return;
    
    for (int i = 0; i < quranText.length; i++) {
      final item = quranText[i];
      final s = item['surah_number'] as int;
      final v = item['verse_number'] as int;
      final page = quran.getPageNumber(s, v);
      
      if (!_pageIndexMap.containsKey(page)) {
        _pageIndexMap[page] = [i, i];
      } else {
        _pageIndexMap[page]![1] = i;
      }
      
      // السماح للـ UI بالتنفس بشكل أكثر تكراراً لتقليل الثقل
      if (i % 300 == 0) await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> _initTafseerAsync() async {
    // تحويل التفسير ليكون Lazy Loading بدلاً من تحميله كاملاً في الرام
    // تم إلغاء الحلقة التكرارية هنا لتوفير الذاكرة والمعالج
    return; 
  }

  String getTafseer(int surah, int ayah) {
    // جلب التفسير مباشرة من ملف البيانات عند الحاجة فقط
    try {
      final item = muyassar.firstWhere(
        (el) => el['sura'] == surah && el['aya'] == ayah,
        orElse: () => {'text': 'التفسير غير متوفر حالياً.'}
      );
      return _removeHtmlTags(item['text'].toString());
    } catch (_) {
      return 'تعذر جلب التفسير.';
    }
  }

  void _loadAyahBookmarks() {
    final box = Hive.box('settings');
    final data = box.get('ayah_bookmarks', defaultValue: []);
    if (data is List) {
      final List<Map<String, dynamic>> converted = data.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{};
      }).toList();
      ayahBookmarks.assignAll(converted);
    }
  }

  void addAyahBookmark(int surah, int ayah, String name, Color color) {
    ayahBookmarks.add({
      'surah': surah,
      'ayah': ayah,
      'name': name,
      'color': color.toARGB32(),
      'date': DateTime.now().toIso8601String(),
    });
    _saveAyahBookmarks();
  }

  void removeAyahBookmark(int surah, int ayah) {
    ayahBookmarks.removeWhere((b) => b['surah'] == surah && b['ayah'] == ayah);
    _saveAyahBookmarks();
  }

  void _saveAyahBookmarks() {
    final box = Hive.box('settings');
    box.put('ayah_bookmarks', ayahBookmarks.toList());
  }

  bool hasAyahBookmark(int surah, int ayah) {
    return ayahBookmarks.any((b) => b['surah'] == surah && b['ayah'] == ayah);
  }

  Color? getAyahBookmarkColor(int surah, int ayah) {
    try {
      final b = ayahBookmarks.firstWhere((b) => b['surah'] == surah && b['ayah'] == ayah);
      return Color(b['color']);
    } catch (_) {
      return null;
    }
  }

  void _loadStarredVerses() {
    final box = Hive.box('settings');
    final data = box.get('starred_verses', defaultValue: <String>[]);
    starredVerses.assignAll(List<String>.from(data));
  }

  void toggleStar(int surah, int ayah) {
    final key = '$surah-$ayah';
    if (starredVerses.contains(key)) {
      starredVerses.remove(key);
    } else {
      starredVerses.add(key);
    }
    final box = Hive.box('settings');
    box.put('starred_verses', starredVerses.toList());
  }

  bool isStarred(int surah, int ayah) {
    return starredVerses.contains('$surah-$ayah');
  }


  String _removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  String removeDiacritics(String text) {
    var diacritics = RegExp(r'[\u064B-\u065F\u06D6-\u06ED]');
    return text.replaceAll(diacritics, '');
  }

  void _loadFawasil() {
    final box = Hive.box('settings');
    final data = box.get('fawasil_list', defaultValue: []);
    if (data is List) {
      final List<Map<String, dynamic>> converted = data.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{};
      }).toList();
      fawasil.assignAll(converted);
    }
  }

  void addFasil(int page, String name) {
    fawasil.add({'page': page, 'name': name, 'date': DateTime.now().toIso8601String()});
    _saveFawasil();
  }

  void removeFasil(int index) {
    fawasil.removeAt(index);
    _saveFawasil();
  }

  void _saveFawasil() {
    final box = Hive.box('settings');
    box.put('fawasil_list', fawasil.toList());
  }

  void _loadBookmark() {
    final box = Hive.box('settings');
    bookmarkedSurah.value = box.get('bookmarked_surah', defaultValue: 0);
    bookmarkedAyah.value = box.get('bookmarked_ayah', defaultValue: 0);
  }

  void saveBookmark(int surah, int ayah) {
    final box = Hive.box('settings');
    bookmarkedSurah.value = surah;
    bookmarkedAyah.value = ayah;
    box.put('bookmarked_surah', surah);
    box.put('bookmarked_ayah', ayah);
    Get.snackbar('تم الحفظ', 'تم حفظ علامة الوقوف عند هذه الآية', 
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  bool isBookmarked(int surah, int ayah) {
    return bookmarkedSurah.value == surah && bookmarkedAyah.value == ayah;
  }

  List<Map<String, dynamic>> getAyahsForPage(int page) {
    if (_pagesCache.containsKey(page)) return _pagesCache[page]!;

    final range = _pageIndexMap[page];
    if (range == null) return [];

    final List<Map<String, dynamic>> pageAyahs = [];
    for (int i = range[0]; i <= range[1]; i++) {
      final ayahData = quranText[i];
      pageAyahs.add({
        'surahNumber': ayahData['surah_number'],
        'ayahNumber': ayahData['verse_number'],
        'text': ayahData['qcfData'].toString(),
        'surahName': quran.getSurahNameArabic(ayahData['surah_number']),
        'juz': quran.getJuzNumber(ayahData['surah_number'], ayahData['verse_number']),
        'hizb': ((page - 1) / 10).floor() + 1,
        'quarter': ((page - 1) / 2.5).floor() + 1,
      });
    }

    _pagesCache[page] = pageAyahs;
    return pageAyahs;
  }

  String getFontFamily(int page) => 'QCF_P${page.toString().padLeft(3, '0')}';

  void onPageChanged(int index) {
    currentPage.value = index + 1;
  }

  void toggleTheme() => isDarkMode.value = !isDarkMode.value;
  void updateFontSize(double size) => fontSize.value = size;
  
  // دالة وهمية لمنع الأخطاء في الملفات الأخرى
  Future<void> loadCurrentPageFont() async {}
}
