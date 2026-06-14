import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/mushaf_controller.dart';

class ScreenShotPreviewPage extends StatefulWidget {
  final int surahNumber;
  final int firstVerse;
  final int lastVerse;
  final bool isQCF;

  const ScreenShotPreviewPage({
    super.key,
    required this.surahNumber,
    required this.firstVerse,
    required this.lastVerse,
    required this.isQCF,
  });

  @override
  State<ScreenShotPreviewPage> createState() => _ScreenShotPreviewPageState();
}

class _ScreenShotPreviewPageState extends State<ScreenShotPreviewPage> {
  double textSize = 22;
  late bool isQCF;
  int selectedThemeIndex = 0;

  // تعريف ألوان الثيمات محلياً لتجنب الأخطاء
  final List<Color> primaryColors = [AppColors.primary, Colors.black, Colors.brown, Colors.blueGrey];
  final List<Color> backgroundColors = [const Color(0xFFFBF9F3), Colors.white, const Color(0xFFFFF8E1), Colors.white];

  @override
  void initState() {
    super.initState();
    isQCF = widget.isQCF;
    textSize = isQCF ? 19 : 22;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('معاينة الآية', style: TextStyle(fontFamily: 'cairo')),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSettings(),
                const SizedBox(height: 30),
                _buildScreenshotArea(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Text('إعدادات الصورة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'cairo')),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('حجم الخط', style: TextStyle(fontFamily: 'cairo')),
                Expanded(
                  child: Slider(
                    value: textSize,
                    min: 15,
                    max: 40,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => textSize = v),
                  ),
                ),
              ],
            ),
            _buildThemePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePicker() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: primaryColors.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => setState(() => selectedThemeIndex = i),
            child: Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: backgroundColors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedThemeIndex == i ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(color: primaryColors[i], shape: BoxShape.circle),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenshotArea() {
    final controller = Get.find<MushafController>();
    
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: backgroundColors[selectedThemeIndex],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            'سورة ${quran.getSurahNameArabic(widget.surahNumber)}',
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColors[selectedThemeIndex],
            ),
          ),
          const Divider(),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: TextStyle(
                color: primaryColors[selectedThemeIndex],
                fontSize: textSize,
                height: 2,
                fontFamily: isQCF ? controller.getFontFamily(quran.getPageNumber(widget.surahNumber, widget.firstVerse)) : 'AmiriQuran',
              ),
              children: _buildVerses(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'غِراس - صدقة جارية',
            style: TextStyle(fontSize: 12, color: primaryColors[selectedThemeIndex].withOpacity(0.5), fontFamily: 'cairo'),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildVerses() {
    List<InlineSpan> spans = [];
    for (int i = widget.firstVerse; i <= widget.lastVerse; i++) {
      spans.add(TextSpan(text: quran.getVerse(widget.surahNumber, i)));
      spans.add(TextSpan(
        text: ' (${_toArabicNumber(i)}) ',
        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
      ));
    }
    return spans;
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.snackbar('قريباً', 'سيتم تفعيل حفظ الصور في التحديث القادم');
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('حفظ في المعرض', style: TextStyle(fontFamily: 'cairo')),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabic[int.parse(d)]).join();
  }
}
