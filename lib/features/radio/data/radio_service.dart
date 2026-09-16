import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'radio_model.dart';

class RadioService {
  static const String _endpoint = 'https://mp3quran.net/api/v3/radios?language=ar';
  static const String _cacheKey = 'cached_radios';
  static final Dio _dio = Dio();

  static Future<List<QuranRadio>> fetchRadios() async {
    try {
      final response = await _dio.get(_endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final List radiosJson = data['radios'];
        final radios = radiosJson.map((e) => QuranRadio.fromJson(e)).toList();
        
        // Cache data
        final box = Hive.box('settings');
        await box.put(_cacheKey, jsonEncode(radiosJson));
        
        return radios;
      } else {
        return _getCachedRadios();
      }
    } catch (e) {
      return _getCachedRadios();
    }
  }

  static List<QuranRadio> _getCachedRadios() {
    final box = Hive.box('settings');
    final cachedData = box.get(_cacheKey);
    if (cachedData != null) {
      final List radiosJson = jsonDecode(cachedData);
      return radiosJson.map((e) => QuranRadio.fromJson(e)).toList();
    }
    return [];
  }
}
