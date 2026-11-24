import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import '../logic/mushaf_controller.dart';
import '../logic/quran_audio_controller.dart';
import '../data/quran_database_service.dart';
import '../../../core/utils/font_service.dart';
import '../../../core/constants/app_colors.dart';
import 'ayah_options_sheet.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  const QuranPageWidget({super.key, required this.pageNumber});

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  late Future<List<QuranLine>> _linesFuture;

  @override
  void initState() {
    super.initState();
    _linesFuture = QuranDatabaseService.getPageLines(widget.pageNumber);
    // تحميل الخط ديناميكياً عند فتح الصفحة
    FontService.preloadFonts(widget.pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final audioController = Get.find<QuranAudioController>();
    final isLeftPage = widget.pageNumber % 2 == 0;

    return FutureBuilder<List<QuranLine>>(
      future: _linesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lines = snapshot.data!;
        if (lines.isEmpty) {
          return const Center(child: Text('جاري التحميل...'));
        }

        QuranWord? firstWord;
        for (var l in lines) {
          if (l.words.isNotEmpty) {
            firstWord = l.words.first;
            break;
          }
        }

        final bool isSpecialPage = widget.pageNumber <= 2;
        final String fontFamily = controller.getFontFamily(widget.pageNumber);

        return Obx(() {
          final isDark = controller.isDarkMode.value;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFEFBF6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: Offset(isLeftPage ? 10 : -10, 0),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableHeight = constraints.maxHeight - 45;
                    final double baseFontSize = (availableHeight / 17.5).clamp(11.0, 22.0);
                    final double calculatedFontSize =
                        baseFontSize * (controller.fontSize.value / 22.0);

                    return Column(
                      children: [
                        const SizedBox(height: 6),
                        _buildHeader(firstWord, isDark),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: lines
                                  .map((line) => _buildLine(
                                        context,
                                        line,
                                        controller,
                                        audioController,
                                        isDark,
                                        calculatedFontSize,
                                        fontFamily,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        _buildFooter(isDark),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(QuranWord? firstWord, bool isDark) {
    if (firstWord == null) return const SizedBox(height: 30);

    final juz = quran.getJuzNumber(firstWord.surah, firstWord.ayah);
    final surahName = quran.getSurahNameArabic(firstWord.surah);
    final page = widget.pageNumber;
    final hizb = ((page - 1) / 10).floor() + 1;
    final globalQuarter = ((page - 1) / 2.5).floor() + 1;
    final quarterInHizb = ((globalQuarter - 1) % 4) + 1;

    String quarterText = '';
    if (quarterInHizb == 2) quarterText = ' - ربع';
    if (quarterInHizb == 3) quarterText = ' - نصف';
    if (quarterInHizb == 4) quarterText = ' - ثلاثة أرباع';

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
            surahName,
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

  // ─── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isDark) {
    final isLeftPage = widget.pageNumber % 2 == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 20, right: 20),
      child: Align(
        alignment: isLeftPage ? Alignment.bottomLeft : Alignment.bottomRight,
        child: Text(
          _toArabicNumber(widget.pageNumber),
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

  // ─── بناء سطر واحد ────────────────────────────────────────────────────────

  Widget _buildLine(
    BuildContext context,
    QuranLine line,
    MushafController controller,
    QuranAudioController audio,
    bool isDark,
    double fontSize,
    String fontFamily,
  ) {
    // سطر اسم السورة
    if (line.lineType == 'surah_name') {
      final surahNum = line.surahNumber ?? 0;
      final name = surahNum > 0 ? quran.getSurahNameArabic(surahNum) : '';
      return _buildSurahBanner(name, isDark);
    }

    // سطر البسملة
    if (line.lineType == 'basmallah') {
      return _buildBasmala(isDark);
    }

    final bool isCentered = line.isCentered;

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: isCentered ? BoxFit.scaleDown : BoxFit.fitWidth,
        alignment: Alignment.center,
        child: RichText(
          textAlign: isCentered ? TextAlign.center : TextAlign.justify,
          textDirection: TextDirection.rtl,
          textWidthBasis: TextWidthBasis.parent,
          locale: const Locale('ar'),
          text: TextSpan(
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.normal,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black,
            ),
            children: _buildWordSpans(
              context,
              line.words,
              controller,
              audio,
              isDark,
            ),
          ),
        ),
      ),
    );
  }

  // ─── كلمات السطر كـ Spans ─────────────────────────────────────────────────

  List<InlineSpan> _buildWordSpans(
    BuildContext context,
    List<QuranWord> words,
    MushafController controller,
    QuranAudioController audio,
    bool isDark,
  ) {
    final List<InlineSpan> spans = [];

    final currentAudioSurah = audio.currentSurah.value;
    final currentAudioAyah = audio.currentAyah.value;
    final selectedKey = controller.selectedAyahKey.value;
    final starredSet = controller.starredVerses;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final ayahKey = '${word.surah}-${word.ayah}';

      final isSelected = currentAudioSurah == word.surah && currentAudioAyah == word.ayah;
      final isSelectedKey = selectedKey == ayahKey;
      final isStarred = starredSet.contains(ayahKey);

      final bookmarkColor = controller.getAyahBookmarkColor(word.surah, word.ayah);
      final isBookmarked = bookmarkColor != null ||
          (controller.bookmarkedSurah.value == word.surah && controller.bookmarkedAyah.value == word.ayah);

      spans.add(TextSpan(
        text: i == 0 ? word.text : ' ${word.text}',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          backgroundColor: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : isSelectedKey
                  ? AppColors.primary.withOpacity(0.15)
                  : isStarred
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
        recognizer: LongPressGestureRecognizer()
          ..onLongPressStart = (_) {
            controller.selectedAyahKey.value = ayahKey;
          }
          ..onLongPressEnd = (_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (controller.selectedAyahKey.value == ayahKey) {
                controller.selectedAyahKey.value = '';
              }
            });
          }
          ..onLongPressCancel = () {
            controller.selectedAyahKey.value = '';
          }
          ..onLongPress = () => AyahOptionsSheet.show(
                context,
                word.surah,
                word.ayah,
                words
                    .where((w) => w.surah == word.surah && w.ayah == word.ayah)
                    .map((w) => w.text)
                    .join(''),
              ),
      ));
    }

    return spans;
  }

  // ─── Surah Banner ─────────────────────────────────────────────────────────

  Widget _buildSurahBanner(String name, bool isDark) {
    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 2),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF8B7355),
          ),
        ),
      ),
    );
  }

  // ─── Basmala ──────────────────────────────────────────────────────────────

  Widget _buildBasmala(bool isDark) {
    final bool isSpecialPage = widget.pageNumber <= 2;
    return SizedBox(
      width: double.infinity,
      height: isSpecialPage ? 46 : 36,
      child: Image.asset(
        'assets/images/Basmala.png',
        fit: BoxFit.contain,
        color: isSpecialPage
            ? const Color(0xFF2E7D32)
            : (isDark ? Colors.white : AppColors.primary.withOpacity(0.9)),
      ),
    );
  }

  // ─── Arabic Numbers ───────────────────────────────────────────────────────

  String _toArabicNumber(int number) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabic[int.parse(d)])
        .join();
  }
}
