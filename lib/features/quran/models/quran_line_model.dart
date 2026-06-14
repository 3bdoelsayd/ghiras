/// كلمة واحدة من القرآن مع معلومات السطر والآية
class QuranWord {
  final String textUthmani;
  final String charType; // 'word' أو 'end' (علامة نهاية الآية)
  final int surahNumber;
  final int? ayahNumber; // مش null إلا لو charType == 'end'

  QuranWord({
    required this.textUthmani,
    required this.charType,
    required this.surahNumber,
    this.ayahNumber,
  });
}

/// سطر كامل من صفحة المصحف (15 سطر في الصفحة عادةً)
class QuranLine {
  final int lineNumber;
  final List<QuranWord> words;

  QuranLine({required this.lineNumber, required this.words});

  /// سطر البسملة لوحده (يُعرض في النص بدون تبرير/justify)
  bool get isBismillahOnly =>
      words.length == 1 &&
      words.first.charType == 'word' &&
      words.first.textUthmani.contains('بِسْمِ');
}
