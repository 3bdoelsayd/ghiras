import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../data/translations/muyassar.dart';
import '../../../core/constants/app_colors.dart';
import '../data/quran_database_service.dart'; // ← الجديد

class MushafController extends GetxController {
  var currentPage = 1.obs;
  var fontSize = 28.0.obs;
  var isDarkMode = false.obs;

  // علامة الوقوف
  var bookmarkedSurah = 0.obs;
  var bookmarkedAyah = 0.obs;

  // الفواصل
  var fawasil = <Map<String, dynamic>>[].obs;

  // العلامات الملونة
  var ayahBookmarks = <Map<String, dynamic>>[].obs;

  // الآيات المفضلة
  var starredVerses = <String>{}.obs;

  // الآية المختارة عند الضغط المطول
  var selectedAyahKey = ''.obs;

  var isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBookmark();
    _loadFawasil();
    _loadAyahBookmarks();
    _loadStarredVerses();
    _initDb();
  }

  Future<void> _initDb() async {
    await QuranDatabaseService.init();
    isReady.value = true;
  }

  // ─── جيب سطور الصفحة من الـ DB ───────────────────────────────────────────

  Future<List<QuranLine>> getLinesForPage(int page) {
    return QuranDatabaseService.getPageLines(page);
  }

  // ─── اسم الخط حسب رقم الصفحة ─────────────────────────────────────────────

  String getFontFamily(int page) =>
      'QCF_P${page.toString().padLeft(3, '0')}';

  // ─── التفسير ──────────────────────────────────────────────────────────────

  String getTafseer(int surah, int ayah) {
    try {
      final item = muyassar.firstWhere(
            (el) => el['sura'] == surah && el['aya'] == ayah,
        orElse: () => {'text': 'التفسير غير متوفر حالياً.'},
      );
      return _removeHtmlTags(item['text'].toString());
    } catch (_) {
      return 'تعذر جلب التفسير.';
    }
  }

  // ─── Ayah Bookmarks ───────────────────────────────────────────────────────

  void _loadAyahBookmarks() {
    final box = Hive.box('settings');
    final data = box.get('ayah_bookmarks', defaultValue: []);
    if (data is List) {
      ayahBookmarks.assignAll(
        data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
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
    ayahBookmarks.removeWhere(
          (b) => b['surah'] == surah && b['ayah'] == ayah,
    );
    _saveAyahBookmarks();
  }

  void _saveAyahBookmarks() =>
      Hive.box('settings').put('ayah_bookmarks', ayahBookmarks.toList());

  bool hasAyahBookmark(int surah, int ayah) =>
      ayahBookmarks.any((b) => b['surah'] == surah && b['ayah'] == ayah);

  Color? getAyahBookmarkColor(int surah, int ayah) {
    try {
      final b = ayahBookmarks
          .firstWhere((b) => b['surah'] == surah && b['ayah'] == ayah);
      return Color(b['color']);
    } catch (_) {
      return null;
    }
  }

  // ─── Starred Verses ───────────────────────────────────────────────────────

  void _loadStarredVerses() {
    final data =
    Hive.box('settings').get('starred_verses', defaultValue: <String>[]);
    starredVerses.assignAll(List<String>.from(data));
  }

  void toggleStar(int surah, int ayah) {
    final key = '$surah-$ayah';
    if (starredVerses.contains(key)) {
      starredVerses.remove(key);
    } else {
      starredVerses.add(key);
    }
    Hive.box('settings').put('starred_verses', starredVerses.toList());
  }

  bool isStarred(int surah, int ayah) =>
      starredVerses.contains('$surah-$ayah');

  // ─── Bookmark ─────────────────────────────────────────────────────────────

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
    Get.snackbar(
      'تم الحفظ',
      'تم حفظ علامة الوقوف عند هذه الآية',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  bool isBookmarked(int surah, int ayah) =>
      bookmarkedSurah.value == surah && bookmarkedAyah.value == ayah;

  // ─── Fawasil ──────────────────────────────────────────────────────────────

  void _loadFawasil() {
    final box = Hive.box('settings');
    final data = box.get('fawasil_list', defaultValue: []);
    if (data is List) {
      fawasil.assignAll(
        data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }
  }

  void addFasil(int page, String name) {
    fawasil.add({
      'page': page,
      'name': name,
      'date': DateTime.now().toIso8601String(),
    });
    _saveFawasil();
  }

  void removeFasil(int index) {
    fawasil.removeAt(index);
    _saveFawasil();
  }

  void _saveFawasil() =>
      Hive.box('settings').put('fawasil_list', fawasil.toList());

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _removeHtmlTags(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');

  String removeDiacritics(String text) =>
      text.replaceAll(RegExp(r'[\u064B-\u065F\u06D6-\u06ED]'), '');

  void onPageChanged(int index) {
    int page = index + 1;
    currentPage.value = page;
    
    // تحميل الصفحات المجاورة مسبقاً لتسريع التقليب
    QuranDatabaseService.preloadPage(page + 1);
    QuranDatabaseService.preloadPage(page - 1);
  }

  void toggleTheme() => isDarkMode.value = !isDarkMode.value;

  void updateFontSize(double size) => fontSize.value = size;

  Future<void> loadCurrentPageFont() async {}
}