import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final int startPage;
  final int endPage;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.startPage,
    required this.endPage,
  });

  @override
  List<Object?> get props => [
    number,
    nameArabic,
    nameEnglish,
    englishNameTranslation,
    numberOfAyahs,
    revelationType,
    startPage,
    endPage,
  ];

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      nameArabic: json['name'] ?? '',
      nameEnglish: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      revelationType: json['revelationType'] ?? '',
      startPage: json['startPage'] ?? 0,
      endPage: json['endPage'] ?? 0,
    );
  }
}

class Ayah extends Equatable {
  final int number;
  final int surahNumber;
  final String text;
  final int page;
  final int line;
  final int juz;
  final int hizb;
  final int rub;

  const Ayah({
    required this.number,
    required this.surahNumber,
    required this.text,
    required this.page,
    required this.line,
    required this.juz,
    required this.hizb,
    required this.rub,
  });

  @override
  List<Object?> get props => [
    number,
    surahNumber,
    text,
    page,
    line,
    juz,
    hizb,
    rub,
  ];

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['numberInSurah'] ?? 0,
      surahNumber: json['surah'] ?? 0,
      text: json['text'] ?? '',
      page: json['page'] ?? 0,
      line: json['line'] ?? 0,
      juz: json['juz'] ?? 0,
      hizb: json['hizb'] ?? 0,
      rub: json['rub'] ?? 0,
    );
  }
}

class QuranPage extends Equatable {
  final int pageNumber;
  final List<Ayah> ayahs;
  final int surahNumber;
  final String surahName;

  const QuranPage({
    required this.pageNumber,
    required this.ayahs,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  List<Object?> get props => [pageNumber, ayahs, surahNumber, surahName];
}
