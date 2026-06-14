class QuranConstants {
  // Quran metadata
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalPages = 604;
  static const int totalJuzs = 30;
  static const int ayahsPerPage = 15; // Average

  // Font settings
  static const String quranFontFamily = 'UthmanicHafs13';
  static const double quranFontSize = 20.0;
  static const double ayahNumberFontSize = 14.0;
  static const double lineHeight = 1.8;

  // Colors
  static const int primaryColor = 0xFF1A5B3D;
  static const int mushafBackgroundColor = 0xFFF5DEB3;
  static const int textColor = 0xFF1A1A1A;
  static const int highlightColor = 0xFFFFE082;

  // Hive box names
  static const String surahsBoxName = 'surahs';
  static const String ayahsBoxName = 'ayahs';
  static const String bookmarksBoxName = 'bookmarks';
  static const String readingProgressBoxName = 'reading_progress';

  // Cache keys
  static const String allSurahsCacheKey = 'all_surahs';
  static const String allAyahsCacheKey = 'all_ayahs';
}
