import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../logic/mushaf_controller.dart';
import '../logic/quran_audio_controller.dart';
import '../../../core/constants/app_colors.dart';
import 'ayah_options_sheet.dart';

class QuranPageWidget extends StatelessWidget {
  final int pageNumber;
  const QuranPageWidget({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final audioController = Get.find<QuranAudioController>();

    return Obx(() {
      final ayahs = controller.getAyahsForPage(pageNumber);
      final isDark = controller.isDarkMode.value;
      final isLeftPage = pageNumber % 2 == 0;

      if (ayahs.isEmpty) {
        return const Center(child: Text('جاري تحميل البيانات...'));
      }

      final isCenteredPage = pageNumber <= 2;

      final double textHeight = pageNumber == 1
          ? 2.1
          : pageNumber == 2
          ? 1.5
          : 1.32;

      final double wordSpacing = pageNumber == 1
          ? 1
          : pageNumber == 2
          ? 1
          : 1;

      final double pageWidth = pageNumber == 1
          ? 800
          : pageNumber == 2
          ? 700
          : 520;

      final double horizontalPadding = pageNumber == 1
          ? 40
          : pageNumber == 2
          ? 40
          : 5;

      return GestureDetector(
        onTap: () {
          if (audioController.isPlaying.value) audioController.stop();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF9F3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: Offset(isLeftPage ? 10 : -10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 5),
              _buildHeader(ayahs, isDark),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: FittedBox(
                      fit: isCenteredPage ? BoxFit.contain : BoxFit.fitWidth,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: pageWidth,
                        child: RichText(
                          textAlign: isCenteredPage
                              ? TextAlign.center
                              : TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          textWidthBasis: TextWidthBasis.parent,
                          locale: const Locale("ar"),
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: controller.getFontFamily(pageNumber),
                              fontSize: 36,
                              height: textHeight,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1200),
                              letterSpacing: 0,
                              wordSpacing: wordSpacing,
                            ),
                            children: _buildSpans(
                              context,
                              ayahs,
                              controller,
                              audioController,
                              isDark,
                              isCenteredPage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildFooter(isDark),
              const SizedBox(height: 2),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(List<Map<String, dynamic>> ayahs, bool isDark) {
    final firstAyah = ayahs.first;
    final juz = firstAyah['juz'];
    final hizb = firstAyah['hizb'];
    final globalQuarter = firstAyah['quarter'] as int;

    final quarterInHizb = ((globalQuarter - 1) % 4) + 1;
    String quarterText = "";
    if (quarterInHizb == 2) quarterText = " - ربع";
    if (quarterInHizb == 3) quarterText = " - نصف";
    if (quarterInHizb == 4) quarterText = " - ثلاثة أرباع";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الجزء $juz - الحزب $hizb$quarterText',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'cairo',
              color: isDark ? Colors.white54 : AppColors.primary,
            ),
          ),
          Text(
            firstAyah['surahName'] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'cairo',
              color: isDark ? Colors.white54 : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final isLeftPage = pageNumber % 2 == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 20, right: 20),
      child: Align(
        alignment: isLeftPage ? Alignment.bottomLeft : Alignment.bottomRight,
        child: Text(
          _toArabicNumber(pageNumber),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : AppColors.primary,
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans(
      BuildContext context,
      List<Map<String, dynamic>> ayahs,
      MushafController controller,
      QuranAudioController audio,
      bool isDark,
      bool isCenteredPage,
      ) {
    final List<InlineSpan> spans = [];
    int? lastSurah;

    for (int i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      final sNum = ayah['surahNumber'] as int;
      final vNum = ayah['ayahNumber'] as int;
      final ayahKey = '$sNum-$vNum';
      final isSelected = audio.currentSurah.value == sNum &&
          audio.currentAyah.value == vNum;
      final isBookmarked = controller.isBookmarked(sNum, vNum);
      final bookmarkColor = controller.getAyahBookmarkColor(sNum, vNum);

      if (vNum == 1 && sNum != lastSurah) {
        lastSurah = sNum;
        spans.add(WidgetSpan(
          child: _buildSurahBanner(
            ayah['surahName'],
            isDark,
            isSpecial: isCenteredPage,
          ),
        ));
        if (sNum != 1 && sNum != 9) {
          spans.add(WidgetSpan(child: _buildBasmala(isDark)));
        }
      }

      spans.add(TextSpan(
        text: ayah['text'],
        style: TextStyle(
          backgroundColor: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : controller.selectedAyahKey.value == ayahKey
              ? AppColors.primary.withOpacity(0.15)
              : controller.isStarred(sNum, vNum)
              ? Colors.amber.withOpacity(0.1)
              : bookmarkColor != null
              ? bookmarkColor.withOpacity(0.2)
              : isBookmarked
              ? Colors.orange.withOpacity(0.15)
              : Colors.transparent,
          decoration: (isBookmarked || bookmarkColor != null)
              ? TextDecoration.underline
              : null,
          decorationColor: bookmarkColor ?? Colors.orange,
        ),
        // تم إلغاء التشغيل عند اللمس العادي بناءً على طلب المستخدم
        recognizer: LongPressGestureRecognizer()
          ..onLongPressStart = (details) {
            controller.selectedAyahKey.value = ayahKey;
          }
          ..onLongPressEnd = (details) {
            controller.selectedAyahKey.value = '';
          }
          ..onLongPress = () =>
              AyahOptionsSheet.show(context, sNum, vNum, ayah['text']),
      ));
    }
    return spans;
  }

  Widget _buildSurahBanner(String name, bool isDark,
      {bool isSpecial = false}) {
    return Container(
      width: double.infinity,
      height: 65,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/888-02.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Center(
        child: Text(
          'سُورَةُ $name',
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF8B7355),
          ),
        ),
      ),
    );
  }

  Widget _buildBasmala(bool isDark) {
    return Container(
      width: double.infinity,
      height: 45,
      margin: const EdgeInsets.only(top: 8, bottom: 5),
      child: Image.asset(
        'assets/images/Basmala.png',
        fit: BoxFit.contain,
        color: isDark
            ? Colors.white
            : AppColors.primary.withOpacity(0.9),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabic[int.parse(d)])
        .join();
  }
}