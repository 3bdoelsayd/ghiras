import 'package:quran/quran.dart' as quran;

class PageSurahMap {
  // تخزين البيانات بعد أول عملية حساب لكي لا تتكرر أبداً
  static Map<int, Map<String, dynamic>>? _cachedMap;

  static Map<int, Map<String, dynamic>> getFullMap() {
    if (_cachedMap != null) return _cachedMap!;
    _cachedMap = {};
    return _cachedMap!;
  }

  static Map<String, dynamic> getPageInfo(int page) {
    _cachedMap ??= {};
    if (_cachedMap!.containsKey(page)) return _cachedMap![page]!;

    int surah = quran.getPageData(page)[0]['surah'];
    int juz = ((page - 2) / 20).floor() + 1;
    if (page <= 21) juz = 1;
    if (juz > 30) juz = 30;
    if (juz < 1) juz = 1;

    final info = {
      'surah': quran.getSurahNameArabic(surah),
      'juz': juz,
      'surahNumber': surah,
    };
    _cachedMap![page] = info;
    return info;
  }
}
