import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/constants/app_colors.dart';
import '../logic/quran_audio_controller.dart';
import '../logic/mushaf_controller.dart';

import 'share_ayah_dialog.dart';
import 'bookmarks_dialog.dart';
import 'tafseer_sheet.dart';

class AyahOptionsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const AyahOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  static void show(BuildContext context, int surah, int ayah, String text) {
    // إخفاء التظليل عند فتح القائمة
    if (Get.isRegistered<MushafController>()) {
      Get.find<MushafController>().selectedAyahKey.value = '';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AyahOptionsSheet(
        surahNumber: surah,
        ayahNumber: ayah,
        ayahText: text,
      ),
    );
  }

  @override
  State<AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<AyahOptionsSheet> {
  final List<Map<String, String>> reciters = [
    {'name': 'مشاري العفاسي', 'id': 'ar.alafasy'},
    {'name': 'عبد الباسط عبد الصمد', 'id': 'ar.abdulsamad'},
    {'name': 'عبد الرحمن السديس', 'id': 'ar.as-sudais'},
    {'name': 'ماهر المعيقلي', 'id': 'ar.mahermuaiqly'},
    {'name': 'سعود الشريم', 'id': 'ar.shuraym'},
    {'name': 'ياسر الدوسري', 'id': 'ar.yasseradosari'},
    {'name': 'محمد صديق المنشاوي', 'id': 'ar.minshawi'},
  ];

  @override
  Widget build(BuildContext context) {
    final audio = Get.find<QuranAudioController>();
    final mushaf = Get.find<MushafController>();
    final isDark = mushaf.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'سورة ${quran.getSurahNameArabic(widget.surahNumber)} - آية ${widget.ayahNumber}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Cairo',
              color: textColor,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),

          _buildRowOption(
            icon: Icons.person_rounded,
            title: 'اختر القارئ',
            color: Colors.blue,
            isDark: isDark,
            trailing: Obx(() => DropdownButton<String>(
                  value: audio.selectedReciter.value,
                  dropdownColor: bgColor,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) audio.selectedReciter.value = newValue;
                  },
                  items: reciters.map<DropdownMenuItem<String>>((reciter) {
                    return DropdownMenuItem<String>(
                      value: reciter['id'],
                      child: Text(
                        reciter['name']!,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: textColor),
                      ),
                    );
                  }).toList(),
                )),
          ),

          _buildRowOption(
            icon: Icons.play_circle_fill_rounded,
            title: 'تشغيل الآية',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              audio.playAyah(widget.surahNumber, widget.ayahNumber);
            },
          ),

          _buildRowOption(
            icon: mushaf.isStarred(widget.surahNumber, widget.ayahNumber)
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            title: mushaf.isStarred(widget.surahNumber, widget.ayahNumber)
                ? 'إزالة من المفضلة'
                : 'إضافة للمفضلة',
            color: Colors.amber,
            isDark: isDark,
            onTap: () {
              mushaf.toggleStar(widget.surahNumber, widget.ayahNumber);
              setState(() {});
            },
          ),

          _buildRowOption(
            icon: (mushaf.hasAyahBookmark(widget.surahNumber, widget.ayahNumber) || 
                   mushaf.isBookmarked(widget.surahNumber, widget.ayahNumber))
                ? Icons.bookmark_added_rounded
                : Icons.bookmark_add_rounded,
            title: (mushaf.hasAyahBookmark(widget.surahNumber, widget.ayahNumber) || 
                   mushaf.isBookmarked(widget.surahNumber, widget.ayahNumber))
                ? 'إزالة العلامة'
                : 'حفظ علامة وقوف',
            color: Colors.redAccent,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              if (mushaf.hasAyahBookmark(widget.surahNumber, widget.ayahNumber) || 
                  mushaf.isBookmarked(widget.surahNumber, widget.ayahNumber)) {
                mushaf.removeAyahBookmark(widget.surahNumber, widget.ayahNumber);
                Get.snackbar('تمت الإزالة', 'تم إزالة العلامة بنجاح',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    colorText: Colors.white);
              } else {
                BookmarksDialog.show(context, widget.surahNumber, widget.ayahNumber);
              }
            },
          ),

          _buildRowOption(
            icon: Icons.menu_book_rounded,
            title: 'التفسير الميسر',
            color: Colors.teal,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              TafseerSheet.show(context, widget.surahNumber, widget.ayahNumber);
            },
          ),

          _buildRowOption(
            icon: Icons.share_rounded,
            title: 'مشاركة الآية',
            color: Colors.orange,
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              ShareAyahDialog.show(context, widget.surahNumber, widget.ayahNumber);
            },
          ),

          _buildRowOption(
            icon: Icons.copy_rounded,
            title: 'نسخ النص',
            color: Colors.grey,
            isDark: isDark,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.ayahText));
              Navigator.pop(context);
              Get.snackbar('تم النسخ', 'تم نسخ نص الآية');
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRowOption({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing else const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showTafseerDialog(BuildContext context, MushafController controller) {
    final tafseer = controller.getTafseer(widget.surahNumber, widget.ayahNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('التفسير الميسر - آية ${widget.ayahNumber}',
            textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(tafseer, textAlign: TextAlign.justify, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, height: 1.6)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo'))),
        ],
      ),
    );
  }
}
