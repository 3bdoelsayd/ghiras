import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FontService {
  static final Set<String> _loadedFonts = {};
  
  // رابط استضافة الخطوط (رابط سريع وموثوق لمخطوطات الملك فهد)
  static const String _baseUrl = 'https://github.com/quran/quran-fonts/raw/master/v2/ttf';

  static Future<void> loadPageFont(int pageNumber) async {
    final fontName = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    if (_loadedFonts.contains(fontName)) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${directory.path}/fonts');
      if (!await fontDir.exists()) await fontDir.create(recursive: true);

      final filePath = '${fontDir.path}/p$pageNumber.ttf';
      final file = File(filePath);

      // 1. التأكد من وجود الملف أو تحميله
      if (!await file.exists()) {
        await _downloadFont(pageNumber, filePath);
      }

      // 2. تحميل الخط في الذاكرة لـ Flutter
      if (await file.exists()) {
        final fontData = await file.readAsBytes();
        final fontLoader = FontLoader(fontName);
        fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
        await fontLoader.load();
        _loadedFonts.add(fontName);
        debugPrint('✅ Loaded font dynamically: $fontName');
      }
    } catch (e) {
      debugPrint('❌ Error loading font $fontName: $e');
    }
  }

  static Future<void> _downloadFont(int pageNumber, String savePath) async {
    try {
      final dio = Dio();
      // رابط الخط بصيغة TTF
      final url = '$_baseUrl/p$pageNumber.ttf';
      await dio.download(url, savePath);
      debugPrint('📥 Downloaded font: p$pageNumber');
    } catch (e) {
      debugPrint('⚠️ Download failed for font p$pageNumber: $e');
    }
  }

  static Future<void> preloadFonts(int currentPage) async {
    // تحميل الصفحة الحالية والصفحات المجاورة لضمان تجربة سلسة (Lazy Loading)
    await loadPageFont(currentPage);
    
    // تحميل 3 صفحات للأمام و 3 للخلف في الخلفية
    for (int i = 1; i <= 3; i++) {
      if (currentPage + i <= 604) loadPageFont(currentPage + i);
      if (currentPage - i >= 1) loadPageFont(currentPage - i);
    }
  }
}
