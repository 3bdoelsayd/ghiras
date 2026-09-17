import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ أضفنا geocoding
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'notification_service.dart';

class PrayerService extends GetxController {
  final _settingsBox = Hive.box('settings');
  
  var prayerTimes = Rxn<PrayerTimes>();
  var nextPrayerName = ''.obs;
  var timeToNextPrayer = ''.obs;
  var currentCity = 'جاري تحديد الموقع...'.obs; 
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    updateSettings();
  }

  Future<void> updateSettings() async {
    try {
      isLoading.value = true;
      
      bool useManual = _settingsBox.get('useManualLocation', defaultValue: false);
      double? lat = _settingsBox.get('lastLat');
      double? lng = _settingsBox.get('lastLng');
      String? cityName = _settingsBox.get('lastCity');

      if (useManual) {
        lat = _settingsBox.get('manualLat', defaultValue: 30.0444);
        lng = _settingsBox.get('manualLng', defaultValue: 31.2357);
        cityName = _settingsBox.get('manualCity', defaultValue: "القاهرة");
      } else if (lat == null || lng == null) {
        // إذا لم يكن هناك موقع محفوظ (أول مرة)، نقوم بتحديده
        try {
          Position position = await _getGeoLocation();
          lat = position.latitude;
          lng = position.longitude;
          
          try {
            await setLocaleIdentifier("ar");
            List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              
              // استخلاص أدق التفاصيل الممكنة
              final village = place.subLocality ?? ""; // القرية أو الحي الصغير
              final area = place.locality ?? "";       // المدينة أو المركز
              final governorate = place.administrativeArea ?? ""; // المحافظة
              
              List<String> parts = [];
              
              // ترتيب منطقي: القرية، المدينة
              if (village.isNotEmpty) parts.add(village);
              if (area.isNotEmpty && area != village) parts.add(area);
              
              // إذا لم نجد قرية أو مدينة، نأخذ اسم الشارع أو المنطقة الإدارية
              if (parts.isEmpty) {
                if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
                  parts.add(place.thoroughfare!);
                }
                if (governorate.isNotEmpty) parts.add(governorate);
              }

              if (parts.isNotEmpty) {
                cityName = parts.join("، ");
              } else {
                cityName = "موقعي الحالي";
              }
            }
          } catch (e) {
            cityName = "موقعي";
          }

          // حفظ الموقع للمرات القادمة
          _settingsBox.put('lastLat', lat);
          _settingsBox.put('lastLng', lng);
          _settingsBox.put('lastCity', cityName);
          
        } catch (e) {
          lat = 30.0444;
          lng = 31.2357;
          cityName = "القاهرة";
        }
      }

      currentCity.value = cityName ?? "القاهرة";
      await _calculatePrayerTimes(lat ?? 30.0444, lng ?? 31.2357);
      _updateNextPrayer();
    } catch (e) {
      debugPrint("Prayer Update Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // إضافة دالة لتحديث الموقع يدوياً إذا رغب المستخدم (مثلاً عند السفر)
  Future<void> refreshLocation() async {
    _settingsBox.delete('lastLat');
    _settingsBox.delete('lastLng');
    _settingsBox.delete('lastCity');
    await updateSettings();
  }

  Future<Position> _getGeoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('خدمة الموقع غير مفعلة');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('تم رفض إذن الوصول للموقع');
    }

    if (permission == LocationPermission.deniedForever) return Future.error('تم رفض إذن الموقع بشكل دائم');

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<void> _calculatePrayerTimes(double lat, double lng) async {
    final coordinates = Coordinates(lat, lng);
    
    String methodKey = _settingsBox.get('calculationMethod', defaultValue: "muslim_world_league");
    CalculationMethod method = _getCalculationMethod(methodKey);
    final params = method.getParameters();
    
    String madhabKey = _settingsBox.get('madhab', defaultValue: "shafi");
    params.madhab = madhabKey == "hanafi" ? Madhab.hanafi : Madhab.shafi;

    params.adjustments.fajr = _settingsBox.get('fajrOffset', defaultValue: 0);
    params.adjustments.sunrise = _settingsBox.get('sunriseOffset', defaultValue: 0);
    params.adjustments.dhuhr = _settingsBox.get('dhuhrOffset', defaultValue: 0);
    params.adjustments.asr = _settingsBox.get('asrOffset', defaultValue: 0);
    params.adjustments.maghrib = _settingsBox.get('maghribOffset', defaultValue: 0);
    params.adjustments.isha = _settingsBox.get('ishaOffset', defaultValue: 0);

    final date = DateComponents.from(DateTime.now());
    prayerTimes.value = PrayerTimes(coordinates, date, params);

    // إلغاء كافة الإشعارات القديمة وإعادة جدولتها بشكل متسلسل مع انتظار التنفيذ
    await _rescheduleAllNotifications();
  }

  Future<void> _rescheduleAllNotifications() async {
    final notificationService = Get.find<NotificationService>();
    
    // إلغاء الإشعارات القديمة بشكل متسلسل
    for (int i = 0; i <= 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final int dayOfYear = _getDayOfYear(date);
      for (int prayerIndex = 0; prayerIndex < 5; prayerIndex++) {
        final int notificationId = (dayOfYear * 10) + prayerIndex;
        await notificationService.cancelNotification(notificationId);
      }
    }
    
    // انتظار انتهاء الحذف قبل بدء الجدولة الجديدة
    await _scheduleAthanNotifications();
  }

  CalculationMethod _getCalculationMethod(String key) {
    switch (key) {
      case "egyptian": return CalculationMethod.egyptian;
      case "umm_al_qura": return CalculationMethod.umm_al_qura;
      case "karachi": return CalculationMethod.karachi;
      case "north_america": return CalculationMethod.north_america;
      case "dubai": return CalculationMethod.dubai;
      case "kuwait": return CalculationMethod.kuwait;
      case "qatar": return CalculationMethod.qatar;
      case "singapore": return CalculationMethod.singapore;
      case "tehran": return CalculationMethod.tehran;
      case "turkey": return CalculationMethod.turkey;
      default: return CalculationMethod.muslim_world_league;
    }
  }

  Future<void> _scheduleAthanNotifications() async {
    if (prayerTimes.value == null) return;
    
    final notificationService = Get.find<NotificationService>();
    final box = Hive.box('settings');

    // التأكد من أن المستخدم مفعل خاصية مواقيت الصلاة بشكل عام
    if (!(box.get('shouldUsePrayerTimes', defaultValue: true))) return;

    debugPrint("Starting Adhan scheduling...");

    // جدولة أذان لمدة 5 أيام قادمة (تقليل المدة لزيادة الثبات)
    for (int i = 0; i <= 5; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final coordinates = prayerTimes.value!.coordinates;
      final params = prayerTimes.value!.calculationParameters;
      
      final times = PrayerTimes(
        coordinates, 
        DateComponents.from(date), 
        params
      );

      final Map<String, DateTime> adhans = {
        'الفجر': times.fajr,
        'الظهر': times.dhuhr,
        'العصر': times.asr,
        'المغرب': times.maghrib,
        'العشاء': times.isha,
      };

      int prayerIndex = 0;
      for (var entry in adhans.entries) {
        final name = entry.key;
        final time = entry.value;
        
        bool isEnabled = box.get('athan_$name', defaultValue: true);
        
        if (isEnabled && time.isAfter(DateTime.now())) {
          final int dayOfYear = _getDayOfYear(date);
          final int notificationId = (dayOfYear * 100) + (date.month * 10) + prayerIndex; // معرف أكثر تميزاً
          
          await notificationService.scheduleNotification(
            id: notificationId,
            title: 'حان الآن موعد صلاة $name',
            body: 'حي على الصلاة، حي على الفلاح',
            scheduledDate: time,
            sound: 'azan',
          );
        }
        prayerIndex++;
      }
    }
    debugPrint("Adhan scheduling completed.");
  }

  int _getDayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  void _updateNextPrayer() {
    if (prayerTimes.value == null) return;

    final now = DateTime.now();
    final next = prayerTimes.value!.nextPrayer();
    
    if (next == Prayer.none) {
      nextPrayerName.value = "الفجر";
    } else {
      nextPrayerName.value = _getArabicName(next);
      final nextTime = prayerTimes.value!.timeForPrayer(next)!;
      final diff = nextTime.difference(now);
      timeToNextPrayer.value = _formatDuration(diff);
    }

    Future.delayed(const Duration(seconds: 30), _updateNextPrayer);
  }

  String _getArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return "الفجر";
      case Prayer.sunrise: return "الشروق";
      case Prayer.dhuhr: return "الظهر";
      case Prayer.asr: return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha: return "العشاء";
      default: return "";
    }
  }

  String _formatDuration(Duration d) {
    String hours = d.inHours.toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }

  void toggleAthan(String prayerName) {
    final box = Hive.box('settings');
    bool currentStatus = box.get('athan_$prayerName', defaultValue: true);
    box.put('athan_$prayerName', !currentStatus);
    
    Get.snackbar(
      'تنبيه',
      'تم ${!currentStatus ? 'تفعيل' : 'إيقاف'} صوت أذان $prayerName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: !currentStatus ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7),
      colorText: Colors.white,
    );

    _scheduleAthanNotifications();
  }

  // دالة لتجربة الأذان فوراً للتأكد من عمل الصوت والإشعارات
  Future<void> testAthan() async {
    final notificationService = Get.find<NotificationService>();
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    
    await notificationService.scheduleNotification(
      id: 999,
      title: 'تجربة الأذان الجديد (V8)',
      body: 'إذا سمعت هذا الصوت، فإن الأذان يعمل بنظام الإشعارات الجديد بنجاح',
      scheduledDate: testTime,
      sound: 'azan',
    );
    
    Get.snackbar(
      'تجربة الأذان',
      'سيتم إطلاق إشعار تجريبي بعد 5 ثوانٍ، يرجى قفل الشاشة للتجربة',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}
