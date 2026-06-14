import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/mushaf_controller.dart';
import '../views/ayah_share_preview.dart';

class ShareAyahDialog extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const ShareAyahDialog({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  static void show(BuildContext context, int surah, int ayah) {
    showDialog(
      context: context,
      builder: (context) => ShareAyahDialog(surahNumber: surah, ayahNumber: ayah),
    );
  }

  @override
  State<ShareAyahDialog> createState() => _ShareAyahDialogState();
}

class _ShareAyahDialogState extends State<ShareAyahDialog> {
  late int fromAyah;
  late int toAyah;
  bool includeTafseer = false;
  bool withoutDiacritics = false;

  @override
  void initState() {
    super.initState();
    fromAyah = widget.ayahNumber;
    toAyah = widget.ayahNumber;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final isDark = controller.isDarkMode.value;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'مشاركة الآيات',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAyahPicker('من آية', fromAyah, (val) {
                setState(() {
                  fromAyah = val!;
                  if (toAyah < fromAyah) toAyah = fromAyah;
                });
              }),
              _buildAyahPicker('إلى آية', toAyah, (val) {
                setState(() {
                  toAyah = val!;
                  if (fromAyah > toAyah) fromAyah = toAyah;
                });
              }),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('إضافة التفسير الميسر', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            value: includeTafseer,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => includeTafseer = val),
          ),
          SwitchListTile(
            title: const Text('نص بدون تشكيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            value: withoutDiacritics,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => withoutDiacritics = val),
          ),
        ],
      ),
      actions: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareText(controller),
                    icon: const Icon(Icons.text_fields_rounded),
                    label: const Text('مشاركة نص', style: TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.to(() => AyahSharePreview(
                        surahNumber: widget.surahNumber,
                        fromAyah: fromAyah,
                        toAyah: toAyah,
                        includeTafseer: includeTafseer,
                      ));
                    },
                    icon: const Icon(Icons.image_rounded, color: Colors.white),
                    label: const Text('مشاركة صورة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAyahPicker(String label, int value, ValueChanged<int?> onChanged) {
    final count = quran.getVerseCount(widget.surahNumber);
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
        DropdownButton<int>(
          value: value,
          items: List.generate(count, (i) => i + 1)
              .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _shareText(MushafController controller) async {
    String shareContent = "";
    final surahName = quran.getSurahNameArabic(widget.surahNumber);

    for (int i = fromAyah; i <= toAyah; i++) {
      String text = quran.getVerse(widget.surahNumber, i, verseEndSymbol: true);
      if (withoutDiacritics) {
        text = controller.removeDiacritics(text);
      }
      shareContent += "$text ";
      
      if (includeTafseer) {
        final tafseer = controller.getTafseer(widget.surahNumber, i);
        shareContent += "\n(التفسير: $tafseer)\n";
      }
    }

    shareContent += "\n\n[سورة $surahName: آية $fromAyah - $toAyah]";
    shareContent += "\nتمت المشاركة من تطبيق غراس";

    await Share.share(shareContent);
    if (mounted) Navigator.pop(context);
  }
}
