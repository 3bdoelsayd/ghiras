import 'package:intl/intl.dart';

class QuranHelpers {
  // Convert page number to surah and ayah
  static Map<String, int> pageToSurahAyah(int page) {
    // This is a simplified mapping - in production, use complete mapping data
    return {'surah': 1, 'ayah': 1};
  }

  // Get juz from page number
  static int getJuzFromPage(int page) {
    return ((page - 1) ~/ 20) + 1; // Approximately 20 pages per juz
  }

  // Format ayah reference
  static String formatAyahReference(int surah, int ayah) {
    return '$surah:$ayah';
  }

  // Get reading time estimate (words per minute)
  static String getReadingTimeEstimate(int wordCount) {
    const wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).toStringAsFixed(0);
    return '$minutes دقيقة';
  }

  // Format date for reading progress
  static String formatReadingDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Check if ayah is in selected page range
  static bool isAyahInPageRange(int ayahPage, int startPage, int endPage) {
    return ayahPage >= startPage && ayahPage <= endPage;
  }

  // Get surah name in Arabic
  static String getSurahNameArabic(int surahNumber) {
    const surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
      'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
      'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
      'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
      'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
      'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
      'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
      'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
      'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
      'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
      'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
      'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
      'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الإنفطار', 'المطففين', 'الانشقاق', 'البروج',
      'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
      'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
      'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
      'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
      'المسد', 'الإخلاص', 'الفلق', 'الناس'
    ];

    if (surahNumber >= 1 && surahNumber <= surahNames.length) {
      return surahNames[surahNumber - 1];
    }
    return '';
  }
}
