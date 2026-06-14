import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/prayer_service.dart';
import '../settings/settings_screen.dart';

class LocationPickerController extends GetxController {
  final _box = Hive.box('settings');
  var isSearching = false.obs;
  var searchError = "".obs;
  var isGpsLoading = false.obs;
  var currentCity = "".obs;

  @override
  void onInit() {
    super.onInit();
    currentCity.value = _box.get('manualCity', defaultValue: "");
  }

  void _onLocationUpdated(String cityName, double lat, double lng, bool isManual) {
    _box.put('manualCity', cityName);
    if (isManual) {
      _box.put('manualLat', lat);
      _box.put('manualLng', lng);
      _box.put('useManualLocation', true);
    } else {
      _box.put('useManualLocation', false);
      _box.delete('manualLat');
      _box.delete('manualLng');
    }
    currentCity.value = cityName;
    
    // تحديث حالة الإعدادات
    try {
      final settingsCtrl = Get.find<SettingsController>();
      settingsCtrl.useManualLocation.value = isManual;
      settingsCtrl.isAutomaticLocation.value = !isManual;
    } catch (_) {}

    Get.find<PrayerService>().updateSettings();
    Get.back();
    Get.snackbar(
      "✅ تم تحديث الموقع",
      "مواقيت الأذان الآن لـ $cityName",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isManual ? AppColors.primary : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> searchCity(String query) async {
    if (query.trim().isEmpty) return;
    isSearching.value = true;
    searchError.value = "";
    try {
      await setLocaleIdentifier("ar");
      List<Location> locs = await locationFromAddress(query.trim());
      if (locs.isEmpty) {
        await setLocaleIdentifier("en");
        locs = await locationFromAddress(query.trim());
      }
      if (locs.isNotEmpty) {
        _onLocationUpdated(query.trim(), locs.first.latitude, locs.first.longitude, true);
      } else {
        searchError.value = "لم يتم العثور على هذا الموقع";
      }
    } catch (_) {
      searchError.value = "تعذر البحث، تحقق من الاتصال";
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> useGps() async {
    isGpsLoading.value = true;
    searchError.value = "";
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        searchError.value = "خدمات الموقع (GPS) معطلة، يرجى تفعيلها";
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        searchError.value = "لم يتم منح إذن الموقع";
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      
      // الحصول على اسم المدينة من الإحداثيات
      String cityName = "موقعي الحالي";
      try {
        List<Placemark> p = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (p.isNotEmpty) cityName = p.first.locality ?? p.first.subAdministrativeArea ?? "موقعي الحالي";
      } catch (_) {}

      _onLocationUpdated(cityName, pos.latitude, pos.longitude, false);
    } catch (e) {
      searchError.value = "فشل تحديد الموقع، تأكد من تشغيل الـ GPS";
    } finally {
      isGpsLoading.value = false;
    }
  }
}

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LocationPickerController());
    final searchCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark), onPressed: () => Get.back()),
        title: const Text("الموقع الجغرافي", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textDark)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.location_on_rounded, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text("حدد موقعك للحصول على مواقيت صلاة دقيقة", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: AppColors.textGrey)),
            const SizedBox(height: 40),
            
            // زر GPS
            Obx(() => ElevatedButton.icon(
              onPressed: ctrl.isGpsLoading.value ? null : ctrl.useGps,
              icon: ctrl.isGpsLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location_rounded),
              label: const Text("استخدام موقعي الحالي (GPS)", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )),
            
            const SizedBox(height: 25),
            Row(children: [const Expanded(child: Divider()), const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("أو ابحث يدوياً", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12))), const Expanded(child: Divider())]),
            const SizedBox(height: 25),

            // مربع البحث
            TextField(
              controller: searchCtrl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "اكتب اسم مدينتك هنا...",
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                prefixIcon: Obx(() => ctrl.isSearching.value ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.search)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) => ctrl.searchCity(v),
            ),

            Obx(() => ctrl.searchError.value.isNotEmpty 
              ? Padding(padding: const EdgeInsets.only(top: 12), child: Text(ctrl.searchError.value, style: const TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12))) 
              : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
