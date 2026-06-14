import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/mushaf_controller.dart';
import '../../../core/constants/app_colors.dart';

class TafseerSheet extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;

  const TafseerSheet({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
  });

  static void show(BuildContext context, int surah, int ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TafseerSheet(surahNumber: surah, verseNumber: ayah),
    );
  }

  @override
  State<TafseerSheet> createState() => _TafseerSheetState();
}

class _TafseerSheetState extends State<TafseerSheet> {
  late int currentAyah;

  @override
  void initState() {
    super.initState();
    currentAyah = widget.verseNumber;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final isDark = controller.isDarkMode.value;
    final totalVerses = quran.getVerseCount(widget.surahNumber);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.5))),
          
          // شريط التنقل العلوي (مستوحى من كودك)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                  onPressed: currentAyah > 1 ? () => setState(() => currentAyah--) : null,
                  color: currentAyah > 1 ? AppColors.primary : Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      'سورة ${quran.getSurahNameArabic(widget.surahNumber)}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      'آية $currentAyah',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                  onPressed: currentAyah < totalVerses ? () => setState(() => currentAyah++) : null,
                  color: currentAyah < totalVerses ? AppColors.primary : Colors.grey[300],
                ),
              ],
            ),
          ),
          const Divider(),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // عرض نص الآية (مستوحى من كودك)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    quran.getVerse(widget.surahNumber, currentAyah),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: controller.getFontFamily(quran.getPageNumber(widget.surahNumber, currentAyah)),
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'التفسير الميسر:',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                // نص التفسير
                Text(
                  controller.getTafseer(widget.surahNumber, currentAyah),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white70 : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
