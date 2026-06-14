import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quran_models.dart';

class QuranRepository {
  static const String _surahsBox = 'surahs';
  static const String _ayahsBox = 'ayahs';
  static const String _pagesBox = 'pages';
  static const String _surahsKey = 'all_surahs';
  static const String _ayahsKey = 'all_ayahs';
  static const String _pagesKey = 'all_pages';

  late Box<dynamic> _surahsHiveBox;
  late Box<dynamic> _ayahsHiveBox;
  late Box<dynamic> _pagesHiveBox;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Open Hive boxes
    _surahsHiveBox = await Hive.openBox(_surahsBox);
    _ayahsHiveBox = await Hive.openBox(_ayahsBox);
    _pagesHiveBox = await Hive.openBox(_pagesBox);

    // Load data from JSON if not cached
    if (_surahsHiveBox.isEmpty) {
      await _loadQuranDataFromJSON();
    }

    _isInitialized = true;
  }

  Future<void> _loadQuranDataFromJSON() async {
    try {
      // Load surahs
      final surahsJson =
          await rootBundle.loadString('assets/json/surahs.json');
      final surahsList = jsonDecode(surahsJson) as List;
      final surahs =
          surahsList.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();

      // Load ayahs (using quran.com API structure)
      final ayahsJson =
          await rootBundle.loadString('assets/json/ayahs_complete.json');
      final ayahsList = jsonDecode(ayahsJson) as List;
      final ayahs =
          ayahsList.map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList();

      // Cache in Hive
      await _surahsHiveBox.put(_surahsKey, jsonEncode(surahs));
      await _ayahsHiveBox.put(_ayahsKey, jsonEncode(ayahs));
    } catch (e) {
      print('Error loading Quran data: $e');
    }
  }

  Future<List<Surah>> getAllSurahs() async {
    try {
      final cached = _surahsHiveBox.get(_surahsKey);
      if (cached != null) {
        final surahsList = jsonDecode(cached) as List;
        return surahsList
            .map((e) => Surah.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting surahs: $e');
    }
    return [];
  }

  Future<List<Ayah>> getSurahAyahs(int surahNumber) async {
    try {
      final cached = _ayahsHiveBox.get(_ayahsKey);
      if (cached != null) {
        final ayahsList = jsonDecode(cached) as List;
        return ayahsList
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .where((ayah) => ayah.surahNumber == surahNumber)
            .toList();
      }
    } catch (e) {
      print('Error getting ayahs: $e');
    }
    return [];
  }

  Future<List<Ayah>> getPageAyahs(int pageNumber) async {
    try {
      final cached = _ayahsHiveBox.get(_ayahsKey);
      if (cached != null) {
        final ayahsList = jsonDecode(cached) as List;
        return ayahsList
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .where((ayah) => ayah.page == pageNumber)
            .toList();
      }
    } catch (e) {
      print('Error getting page ayahs: $e');
    }
    return [];
  }

  Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    try {
      final cached = _ayahsHiveBox.get(_ayahsKey);
      if (cached != null) {
        final ayahsList = jsonDecode(cached) as List;
        final result = ayahsList
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .firstWhere(
              (ayah) =>
                  ayah.surahNumber == surahNumber && ayah.number == ayahNumber,
              orElse: () => const Ayah(
                number: 0,
                surahNumber: 0,
                text: '',
                page: 0,
                line: 0,
                juz: 0,
                hizb: 0,
                rub: 0,
              ),
            );
        return result.number != 0 ? result : null;
      }
    } catch (e) {
      print('Error getting ayah: $e');
    }
    return null;
  }

  Future<Surah?> getSurah(int surahNumber) async {
    try {
      final surahs = await getAllSurahs();
      return surahs.firstWhere(
        (surah) => surah.number == surahNumber,
        orElse: () => const Surah(
          number: 0,
          nameArabic: '',
          nameEnglish: '',
          englishNameTranslation: '',
          numberOfAyahs: 0,
          revelationType: '',
          startPage: 0,
          endPage: 0,
        ),
      );
    } catch (e) {
      print('Error getting surah: $e');
    }
    return null;
  }

  // Get all ayahs for a juz
  Future<List<Ayah>> getJuzAyahs(int juzNumber) async {
    try {
      final cached = _ayahsHiveBox.get(_ayahsKey);
      if (cached != null) {
        final ayahsList = jsonDecode(cached) as List;
        return ayahsList
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .where((ayah) => ayah.juz == juzNumber)
            .toList();
      }
    } catch (e) {
      print('Error getting juz ayahs: $e');
    }
    return [];
  }

  // Search in Quran
  Future<List<Ayah>> searchQuran(String query) async {
    try {
      final cached = _ayahsHiveBox.get(_ayahsKey);
      if (cached != null) {
        final ayahsList = jsonDecode(cached) as List;
        return ayahsList
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .where((ayah) => ayah.text.contains(query))
            .toList();
      }
    } catch (e) {
      print('Error searching quran: $e');
    }
    return [];
  }

  void dispose() {
    _surahsHiveBox.close();
    _ayahsHiveBox.close();
    _pagesHiveBox.close();
  }
}
