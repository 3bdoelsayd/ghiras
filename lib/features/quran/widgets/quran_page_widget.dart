import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import '../logic/mushaf_controller.dart';
import '../logic/quran_audio_controller.dart';
import '../data/quran_database_service.dart';
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

        // تحسين: جلب أول كلمة بطريقة أسرع
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

          return Container(
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
            child: Column(
              children: [
                const SizedBox(height: 14),
                _buildHeader(firstWord, isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: isSpecialPage
                        ? SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          if (isSpecialPage) SizedBox(height: 60.h),
                          ...lines.map((line) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.h),
                            child: _buildLine(
                              context,
                              line,
                              controller,
                              audioController,
                              isDark,
                              22.sp,
                              fontFamily,
                            ),
                          )),
                        ],
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: lines
                          .map((line) => _buildLine(
                        context,
                        line,
                        controller,
                        audioController,
                        isDark,
                        21.sp,
                        fontFamily,
                      ))
                          .toList(),
                    ),
                  ),
                ),
                _buildFooter(isDark),
                const SizedBox(height: 10),
              ],
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

    // لضمان ملء السطر بالكامل (Justification) نستخدم Row مع MainAxisAlignment.spaceBetween
    // يتم تطبيق هذا فقط على أسطر الآيات غير الممركزة
    if (!line.isCentered && line.words.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: _buildWordWidgets(
            context,
            line.words,
            controller,
            audio,
            isDark,
            fontSize,
            fontFamily,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        textWidthBasis: TextWidthBasis.parent,
        maxLines: 1,
        locale: const Locale('ar'),
        text: TextSpan(
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            height: 1.6,
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
    );
  }

  // ─── بناء الكلمات كـ Widgets لتوزيعها في السطر ──────────────────────────

  List<Widget> _buildWordWidgets(
      BuildContext context,
      List<QuranWord> words,
      MushafController controller,
      QuranAudioController audio,
      bool isDark,
      double fontSize,
      String fontFamily,
      ) {
    final currentAudioSurah = audio.currentSurah.value;
    final currentAudioAyah = audio.currentAyah.value;
    final selectedKey = controller.selectedAyahKey.value;
    final starredSet = controller.starredVerses;

    return words.map((word) {
      final ayahKey = '${word.surah}-${word.ayah}';
      final isSelected = currentAudioSurah == word.surah && currentAudioAyah == word.ayah;
      final isSelectedKey = selectedKey == ayahKey;
      final isStarred = starredSet.contains(ayahKey);
      final bookmarkColor = controller.getAyahBookmarkColor(word.surah, word.ayah);
      final isBookmarked = bookmarkColor != null ||
          (controller.bookmarkedSurah.value == word.surah && controller.bookmarkedAyah.value == word.ayah);

      return GestureDetector(
        onLongPressStart: (_) => controller.selectedAyahKey.value = ayahKey,
        onLongPressEnd: (_) => controller.selectedAyahKey.value = '',
        onLongPress: () => AyahOptionsSheet.show(
          context,
          word.surah,
          word.ayah,
          words
              .where((w) => w.surah == word.surah && w.ayah == word.ayah)
              .map((w) => w.text)
              .join(''),
        ),
        child: Text(
          word.text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            height: 1.6,
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
        ),
      );
    }).toList();
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

    // تحسين: جلب القيم مرة واحدة خارج الحلقة
    final currentAudioSurah = audio.currentSurah.value;
    final currentAudioAyah = audio.currentAyah.value;
    final selectedKey = controller.selectedAyahKey.value;
    final starredSet = controller.starredVerses;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final ayahKey = '${word.surah}-${word.ayah}';

      // التحقق من الحالات بطريقة أسرع
      final isSelected = currentAudioSurah == word.surah && currentAudioAyah == word.ayah;
      final isSelectedKey = selectedKey == ayahKey;
      final isStarred = starredSet.contains(ayahKey);

      // تقليل استدعاءات البحث في المصفوفات
      final bookmarkColor = controller.getAyahBookmarkColor(word.surah, word.ayah);
      final isBookmarked = bookmarkColor != null || (controller.bookmarkedSurah.value == word.surah && controller.bookmarkedAyah.value == word.ayah);

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
          decoration:
          (isBookmarked || bookmarkColor != null)
              ? TextDecoration.underline
              : null,
          decorationColor: bookmarkColor ?? Colors.orange,
        ),
        recognizer: LongPressGestureRecognizer()
          ..onLongPressStart = (_) {
            controller.selectedAyahKey.value = ayahKey;
          }
          ..onLongPressEnd = (_) {
            controller.selectedAyahKey.value = '';
          }
          ..onLongPress = () => AyahOptionsSheet.show(
            context,
            word.surah,
            word.ayah,
            words
                .where((w) =>
            w.surah == word.surah && w.ayah == word.ayah)
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
      height: 52,
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
      height: isSpecialPage ? 48 : 38,
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