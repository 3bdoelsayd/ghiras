import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ أضفنا geocoding
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
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
      double lat, lng;
      String cityName;

      if (useManual) {
        lat = _settingsBox.get('manualLat', defaultValue: 30.0444);
        lng = _settingsBox.get('manualLng', defaultValue: 31.2357);
        cityName = _settingsBox.get('manualCity', defaultValue: "القاهرة");
      } else {
        try {
          Position position = await _getGeoLocation();
          lat = position.latitude;
          lng = position.longitude;
          
          // ✅ محاولة جلب العنوان التفصيلي
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              List<String> parts = [];
              if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
              if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
              if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);
              
              cityName = parts.join("، "); // استخدام الفاصلة العربية
              if (cityName.isEmpty) cityName = "موقعي الحالي";
            } else {
              cityName = "موقعي الحالي";
            }
          } catch (e) {
            cityName = "موقعي الحالي";
          }
          
        } catch (e) {
          lat = 30.0444;
          lng = 31.2357;
          cityName = "القاهرة (افتراضي)";
        }
      }

      currentCity.value = cityName;
      _calculatePrayerTimes(lat, lng);
      _updateNextPrayer();
    } catch (e) {
      debugPrint("Prayer Update Error: $e");
    } finally {
      isLoading.value = false;
    }
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

    return await Geolocator.getCurrentPosition();
  }

  void _calculatePrayerTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    
    String methodKey = _settingsBox.get('calculationMethod', defaultValue: "muslim_world_league");
    CalculationMethod method = _getCalculationMethod(methodKey);
    final params = method.getParameters();
    
    String madhabKey = _settingsBox.get('madhab', defaultValue: "shafi");
    params.madhab = madhabKey == "hanafi" ? Madhab.hanafi : Madhab.shafi;

    params.adjustments.fajr = _settingsBox.get('fajrOffset', defaultValue: 0);
    params.adjustments.dhuhr = _settingsBox.get('dhuhrOffset', defaultValue: 0);
    params.adjustments.asr = _settingsBox.get('asrOffset', defaultValue: 0);
    params.adjustments.maghrib = _settingsBox.get('maghribOffset', defaultValue: 0);
    params.adjustments.isha = _settingsBox.get('ishaOffset', defaultValue: 0);

    final date = DateComponents.from(DateTime.now());
    prayerTimes.value = PrayerTimes(coordinates, date, params);

    _scheduleAthanNotifications();
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

  void _scheduleAthanNotifications() {
    if (prayerTimes.value == null) return;
    
    final notificationService = Get.find<NotificationService>();
    final box = Hive.box('settings');

    // جدولة أذان اليوم وغداً لضمان استمرارية التنبيهات
    for (int i = 0; i <= 1; i++) {
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

      adhans.forEach((name, time) {
        // التحقق مما إذا كان الأذان مفعلاً لهذا الوقت
        bool isEnabled = box.get('athan_$name', defaultValue: true);
        
        if (isEnabled && time.isAfter(DateTime.now())) {
          notificationService.scheduleNotification(
            id: "$name-$i".hashCode, // ID فريد لكل يوم
            title: 'حان الآن موعد أذان $name',
            body: 'حي على الصلاة، حي على الفلاح',
            scheduledDate: time,
            sound: 'azan', // استخدام ملف azan.mp3 الموجود في الـ raw
          );
        }
      });
    }
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
}