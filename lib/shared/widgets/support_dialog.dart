import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // سأتحقق من وجود المكتبة أو استخدم بديل
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SupportDialog extends StatelessWidget {
  const SupportDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SupportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
          "دعم التطبيق",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "تطبيق غراس خالٍ تماماً من الإعلانات لضمان أفضل تجربة للمستخدم.",
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "غِراس تطبيق صدقة جارية، دعمك لنا بالتقييم أو المساهمة يساعدنا على الاستمرار وتطويره.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          const SizedBox(height: 20),
          
          // خيار التقييم
          _buildOption(
            icon: Icons.star_rate_rounded,
            title: "تقييم التطبيق",
            subtitle: "قيمنا بـ 5 نجوم على المتجر",
            color: Colors.amber,
            onTap: () {
              // فتح لينك المتجر
            },
          ),
          const SizedBox(height: 12),

          // خيار فودافون كاش
          _buildOption(
            icon: Icons.phone_android_rounded,
            title: "فودافون كاش",
            subtitle: "01070753890",
            color: Colors.red,
            isCopyable: true,
            copyValue: "01070753890",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إغلاق", style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary)),
        )
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isCopyable = false,
    String? copyValue,
  }) {
    return InkWell(
      onTap: isCopyable ? () {
        Clipboard.setData(ClipboardData(text: copyValue!));
        Get.snackbar(
          "تم النسخ",
          "تم نسخ رقم $title",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
      } : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(isCopyable ? Icons.copy_rounded : Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
