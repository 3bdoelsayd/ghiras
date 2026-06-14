import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quran_line_model.dart';

/// يجيب نص الصفحة مقسّم سطر بسطر (15 سطر) من Quran.com API
/// ويخزّنه محليًا (Hive) عشان يشتغل أوفلاين بعد أول مرة.
class QuranPageService {
  static const _baseUrl = 'https://api.quran.com/api/v4/verses/by_page';

  // كاش في الذاكرة لتجنب إعادة المعالجة وقت التنقل بين الصفحات
  static final Map<int, List<QuranLine>> _memoryCache = {};

  static Future<List<QuranLine>> getPageLines(int pageNumber) async {
    if (_memoryCache.containsKey(pageNumber)) {
      return _memoryCache[pageNumber]!;
    }

    final box = await Hive.openBox('quran_pages_cache');
    final cachedJson = box.get('page_$pageNumber') as String?;

    Map<String, dynamic> data;

    if (cachedJson != null) {
      data = jsonDecode(cachedJson) as Map<String, dynamic>;
    } else {
      final uri = Uri.parse(
        '$_baseUrl/$pageNumber'
        '?words=true'
        '&word_fields=text_uthmani,line_number,char_type_name'
        '&fields=text_uthmani',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('فشل تحميل بيانات الصفحة $pageNumber');
      }

      data = jsonDecode(response.body) as Map<String, dynamic>;
      // نخزن الاستجابة كاملة عشان نستخدمها أوفلاين بعد كده
      await box.put('page_$pageNumber', response.body);
    }

    final lines = _groupByLine(data);
    _memoryCache[pageNumber] = lines;
    return lines;
  }

  static List<QuranLine> _groupByLine(Map<String, dynamic> data) {
    final Map<int, List<QuranWord>> grouped = {};

    for (final verse in (data['verses'] as List)) {
      final verseKey = verse['verse_key'].toString();
      final surahNumber = int.parse(verseKey.split(':')[0]);
      final verseNumber = verse['verse_number'] as int;

      for (final word in (verse['words'] as List)) {
        final lineNo = word['line_number'] as int;
        grouped.putIfAbsent(lineNo, () => []);
        grouped[lineNo]!.add(
          QuranWord(
            textUthmani: (word['text_uthmani'] ?? '').toString(),
            charType: (word['char_type_name'] ?? 'word').toString(),
            surahNumber: surahNumber,
            ayahNumber:
                word['char_type_name'] == 'end' ? verseNumber : null,
          ),
        );
      }
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys
        .map((k) => QuranLine(lineNumber: k, words: grouped[k]!))
        .toList();
  }
}
