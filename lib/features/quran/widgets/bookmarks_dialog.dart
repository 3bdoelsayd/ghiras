import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../logic/mushaf_controller.dart';
import '../../../core/constants/app_colors.dart';

class BookmarksDialog extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const BookmarksDialog({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  static void show(BuildContext context, int surah, int ayah) {
    showDialog(
      context: context,
      builder: (context) => BookmarksDialog(surahNumber: surah, ayahNumber: ayah),
    );
  }

  @override
  State<BookmarksDialog> createState() => _BookmarksDialogState();
}

class _BookmarksDialogState extends State<BookmarksDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final isDark = controller.isDarkMode.value;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'إضافة علامة للآية',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'اسم العلامة (اختياري)',
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اختر لون العلامة:', style: TextStyle(fontFamily: 'Cairo')),
              GestureDetector(
                onTap: _showColorPickerDialog,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          onPressed: () {
            controller.addAyahBookmark(
              widget.surahNumber,
              widget.ayahNumber,
              _nameController.text.isEmpty ? 'علامة جديدة' : _nameController.text,
              _selectedColor,
            );
            Navigator.pop(context);
            Get.snackbar('تم الحفظ', 'تم إضافة العلامة بنجاح',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: _selectedColor.withOpacity(0.8),
                colorText: Colors.white);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللون', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
