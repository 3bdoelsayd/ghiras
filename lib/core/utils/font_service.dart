import 'package:flutter/services.dart';
import 'dart:typed_data';

class FontService {
  static final Set<String> _loadedFonts = {};

  static Future<void> loadPageFont(int pageNumber) async {
    final fontName = 'p$pageNumber';
    if (_loadedFonts.contains(fontName)) return;

    try {
      final fontLoader = FontLoader(fontName);
      // Loading .woff files from the user's directory
      final fontData = await rootBundle.load('assets/fonts/quran_fonts/p$pageNumber.woff');
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      _loadedFonts.add(fontName);
      print('Successfully loaded font: $fontName');
    } catch (e) {
      print('Error loading font $fontName: $e');
      // Fallback to ttf if woff fails (checking the other directory in user's screenshot)
      try {
        final fontLoader = FontLoader(fontName);
        final fontData = await rootBundle.load('assets/fonts/qcf4_ttf/p$pageNumber.ttf');
        fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
        await fontLoader.load();
        _loadedFonts.add(fontName);
        print('Successfully loaded font from TTF fallback: $fontName');
      } catch (e2) {
        print('Final fallback failed for $fontName: $e2');
      }
    }
  }

  static Future<void> preloadFonts(int currentPage) async {
    await loadPageFont(currentPage);
    if (currentPage < 604) await loadPageFont(currentPage + 1);
    if (currentPage > 1) await loadPageFont(currentPage - 1);
    
    // Batch load some surrounding pages in the background
    for (int i = 1; i <= 5; i++) {
      if (currentPage + i <= 604) loadPageFont(currentPage + i);
      if (currentPage - i >= 1) loadPageFont(currentPage - i);
    }
  }
}
