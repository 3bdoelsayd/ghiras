import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:adhan/adhan.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/prayer_service.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/string_utils.dart';
import '../../shared/widgets/setting_section_header.dart';
import 'settings_screen.dart';

class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إعدادات المواقيت',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20, 
            fontFamily: 'Cairo',
            color: AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showResetConfirm(context, controller),
            child: const Text("إعادة ضبط", style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingSectionHeader(title: "الموقع"),
          _buildSelectionTile(
            "تغيير الموقع", 
            "تحديد المدينة أو استخدام GPS",
            () => context.push(AppRouter.locationPicker)
          ),

          const Divider(height: 32),

          const SettingSectionHeader(title: "تعديل المواقيت يدوياً (دقائق)"),
          _buildOffsetRow("الفجر", 'fajrOffset', controller.fajrOffset, controller, Prayer.fajr),
          _buildOffsetRow("الشروق", 'sunriseOffset', controller.sunriseOffset, controller, Prayer.sunrise),
          _buildOffsetRow("الظهر", 'dhuhrOffset', controller.dhuhrOffset, controller, Prayer.dhuhr),
          _buildOffsetRow("العصر", 'asrOffset', controller.asrOffset, controller, Prayer.asr),
          _buildOffsetRow("المغرب", 'maghribOffset', controller.maghribOffset, controller, Prayer.maghrib),
          _buildOffsetRow("العشاء", 'ishaOffset', controller.ishaOffset, controller, Prayer.isha),
          
          const Divider(height: 32),
          
          const SettingSectionHeader(title: "طريقة الحساب"),
          Obx(() => _buildSelectionTile(
            "طريقة الحساب", 
            controller.calculationMethodsNames[controller.calculationMethod.value] ?? "",
            () => _showCalculationMethodPicker(context, controller)
          )),
          Obx(() => _buildSelectionTile(
            "مذهب صلاة العصر", 
            controller.madhabNames[controller.madhab.value] ?? "",
            () => _showMadhabPicker(context, controller)
          )),
          
          const Divider(height: 32),
          
          const SettingSectionHeader(title: "تنبيهات الأذان"),
          _buildAthanToggles(),

          const Divider(height: 40),
          
          ElevatedButton.icon(
            onPressed: () => Get.find<PrayerService>().testAthan(),
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            label: const Text(
              "تجربة صوت الأذان الآن", 
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "هذا الزر يقوم بتجربة الأذان بعد 5 ثوانٍ للتأكد من عمل الصوت والإشعارات في الخلفية.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


  void _showResetConfirm(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إعادة ضبط المواقيت", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text("هل تريد حقاً إلغاء كافة التعديلات اليدوية والعودة للحسابات التلقائية؟", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(onPressed: () { controller.resetOffsets(); Navigator.pop(context); }, child: const Text("نعم، إعادة ضبط", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _buildAthanToggles() {
    final controller = Get.find<SettingsController>();
    
    return Column(
      children: [
        _buildAthanSwitch("الفجر", controller.fajrAthanEnabled, controller),
        _buildAthanSwitch("الظهر", controller.dhuhrAthanEnabled, controller),
        _buildAthanSwitch("العصر", controller.asrAthanEnabled, controller),
        _buildAthanSwitch("المغرب", controller.maghribAthanEnabled, controller),
        _buildAthanSwitch("العشاء", controller.ishaAthanEnabled, controller),
      ],
    );
  }

  Widget _buildAthanSwitch(String name, RxBool val, SettingsController controller) {
    return Obx(() => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text("أذان $name", textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
      value: val.value,
      activeColor: AppColors.primary,
      onChanged: (v) => controller.toggleAthanStatus(name),
    ));
  }

  Widget _buildOffsetRow(String name, String key, RxInt val, SettingsController controller, Prayer prayer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary),
                onPressed: () { val.value++; controller.saveOffset(key, val.value); },
              ),
              Obx(() => Container(
                width: 45,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  val.value.toString().toArabicDigits, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                ),
              )),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 28, color: Colors.grey),
                onPressed: () { val.value--; controller.saveOffset(key, val.value); },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Obx(() {
                final prayerTimes = Get.find<PrayerService>().prayerTimes.value;
                if (prayerTimes == null) return const SizedBox.shrink();
                final time = prayerTimes.timeForPrayer(prayer);
                if (time == null) return const SizedBox.shrink();
                return Text(
                  intl.DateFormat.jm('ar').format(time),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile(String title, String current, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey),
      title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
      subtitle: Text(current, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
      onTap: onTap,
    );
  }

  void _showCalculationMethodPicker(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختر طريقة الحساب", style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: controller.calculationMethodsNames.entries.map((e) => ListTile(
                  title: Text(e.value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: controller.calculationMethod.value == e.key ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    controller.updateCalculationMethod(e.key);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMadhabPicker(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختر مذهب صلاة العصر", style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...controller.madhabNames.entries.map((e) => ListTile(
              title: Text(e.value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo')),
              trailing: controller.madhab.value == e.key ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () {
                controller.updateMadhab(e.key);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, RxBool val) {
    return Obx(() => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Switch(
        value: val.value,
        activeColor: Colors.green,
        onChanged: (v) => val.value = v,
      ),
      title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
    ));
  }

}
