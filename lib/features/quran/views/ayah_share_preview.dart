import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/mushaf_controller.dart';
import '../data/quran_text.dart';

class AyahSharePreview extends StatefulWidget {
  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final bool includeTafseer;

  const AyahSharePreview({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.includeTafseer = false,
  });

  @override
  State<AyahSharePreview> createState() => _AyahSharePreviewState();
}

class _AyahSharePreviewState extends State<AyahSharePreview> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final MushafController _controller = Get.find<MushafController>();
  
  int _selectedThemeIndex = 0;
  double _fontSize = 22.0;
  TextAlign _alignment = TextAlign.center;
  bool _isQCF = true;

  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'كلاسيك',
      'background': const Color(0xFFFBF9F3),
      'text': const Color(0xFF2D2D2D),
      'accent': const Color(0xFF8B4513),
    },
    {
      'name': 'داكن',
      'background': const Color(0xFF1A1A1A),
      'text': const Color(0xFFE0E0E0),
      'accent': const Color(0xFFC19A6B),
    },
    {
      'name': 'أزرق',
      'background': const Color(0xFFE3F2FD),
      'text': const Color(0xFF0D47A1),
      'accent': const Color(0xFF1976D2),
    },
    {
      'name': 'أخضر',
      'background': const Color(0xFFE8F5E9),
      'text': const Color(0xFF1B5E20),
      'accent': const Color(0xFF43A047),
    },
  ];

  String _getAyahText(int surah, int ayah, bool qcf) {
    if (qcf) {
      try {
        final ayahData = quranText.firstWhere(
          (element) => element['surah_number'] == surah && element['verse_number'] == ayah
        );
        return ayahData['qcfData'].toString();
      } catch (e) {
        return quran.getVerse(surah, ayah);
      }
    }
    return quran.getVerse(surah, ayah);
  }

  String _getFontFamily(int surah, int ayah) {
    if (!_isQCF) return 'AmiriQuran';
    final page = quran.getPageNumber(surah, ayah);
    return 'QCF_P${page.toString().padLeft(3, '0')}';
  }

  Future<void> _shareImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/ayah_share.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([XFile(imagePath.path)], text: 'تمت المشاركة من تطبيق غراس');
  }

  String _toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = _themes[_selectedThemeIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('معاينة المشاركة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: currentTheme['background'],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: currentTheme['accent'].withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'سورة ${quran.getSurahNameArabic(widget.surahNumber)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              color: currentTheme['accent'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Image.asset('assets/images/iconlauncher.png', height: 24),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      // Bismillah
                      if (widget.fromAyah == 1 && widget.surahNumber != 1 && widget.surahNumber != 9)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            quran.basmala,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: _fontSize.sp,
                              color: currentTheme['text'],
                            ),
                          ),
                        ),

                      // Ayahs
                      RichText(
                        textAlign: _alignment,
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          children: List.generate(widget.toAyah - widget.fromAyah + 1, (index) {
                            final ayahNum = widget.fromAyah + index;
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: _getAyahText(widget.surahNumber, ayahNum, _isQCF),
                                  style: TextStyle(
                                    fontFamily: _getFontFamily(widget.surahNumber, ayahNum),
                                    fontSize: _fontSize.sp,
                                    color: currentTheme['text'],
                                    height: 1.8,
                                  ),
                                ),
                                if (!_isQCF)
                                  TextSpan(
                                    text: ' \uFD3F${_toArabicNumbers(ayahNum.toString())}\uFD3E ',
                                    style: TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: (_fontSize * 0.8).sp,
                                      color: currentTheme['accent'],
                                    ),
                                  )
                                else
                                  const TextSpan(text: ' '),
                              ],
                            );
                          }),
                        ),
                      ),

                      if (widget.includeTafseer) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        ...List.generate(widget.toAyah - widget.fromAyah + 1, (index) {
                          final ayahNum = widget.fromAyah + index;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_controller.getTafseer(widget.surahNumber, ayahNum)} (${_toArabicNumbers(ayahNum.toString())})',
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.sp,
                                color: currentTheme['text'].withOpacity(0.8),
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'تطبيق غراس - صدقة جارية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.sp,
                          color: currentTheme['text'].withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme selector
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _themes.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedThemeIndex = index),
                        child: Container(
                          width: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: _themes[index]['background'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedThemeIndex == index ? AppColors.primary : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(color: _themes[index]['text'], shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                // Font size slider
                Row(
                  children: [
                    const Icon(Icons.format_size, size: 20, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 15,
                        max: 40,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _fontSize = val),
                      ),
                    ),
                    const Icon(Icons.format_size, size: 30, color: Colors.grey),
                  ],
                ),
                // Alignment and QCF toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.align_horizontal_center, color: _alignment == TextAlign.center ? AppColors.primary : Colors.grey),
                      onPressed: () => setState(() => _alignment = TextAlign.center),
                    ),
                    IconButton(
                      icon: Icon(Icons.align_horizontal_right, color: _alignment == TextAlign.right ? AppColors.primary : Colors.grey),
                      onPressed: () => setState(() => _alignment = TextAlign.right),
                    ),
                    const VerticalDivider(),
                    ChoiceChip(
                      label: const Text('خط مصحف', style: TextStyle(fontFamily: 'Cairo')),
                      selected: _isQCF,
                      onSelected: (val) => setState(() => _isQCF = val),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _shareImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('مشاركة الصورة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
