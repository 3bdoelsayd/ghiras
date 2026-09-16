import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hijri/hijri_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_router.dart';
import '../../shared/widgets/setting_section_header.dart';
import '../../shared/widgets/support_dialog.dart';

class SettingsController extends GetxController {
  final box = Hive.box('settings');

  var fajrOffset = 0.obs;
  var sunriseOffset = 0.obs;
  var dhuhrOffset = 0.obs;
  var asrOffset = 0.obs;
  var maghribOffset = 0.obs;
  var ishaOffset = 0.obs;

  // ✅ تفعيل/إيقاف الأذان لكل صلاة
  var fajrAthanEnabled = true.obs;
  var dhuhrAthanEnabled = true.obs;
  var asrAthanEnabled = true.obs;
  var maghribAthanEnabled = true.obs;
  var ishaAthanEnabled = true.obs;

  var morningAthkarEnabled = true.obs;
  var morningAthkarHour = 7.obs;
  var morningAthkarMinute = 0.obs;

  var eveningAthkarEnabled = true.obs;
  var eveningAthkarHour = 17.obs;
  var eveningAthkarMinute = 30.obs;

  var quranReminderEnabled = true.obs;

  var useManualLocation = false.obs;
  var isAutomaticLocation = true.obs;
  var manualLocationName = "القاهرة".obs;
  var manualGovernorate = "".obs;

  // ✅ للموقع اليدوي المخصص
  var isSearchingCity = false.obs;
  var searchError = "".obs;

  final Map<String, List<double>> egyptianCities = {
    "القاهرة": [30.0444, 31.2357],
    "الإسكندرية": [31.2001, 29.9187],
    "المنصورة": [31.0409, 31.3785],
    "طنطا": [30.7865, 31.0004],
    "أسيوط": [27.1783, 31.1859],
    "المنيا": [28.0991, 30.75],
    "الأقصر": [25.6872, 32.6396],
    "أسوان": [24.0889, 32.8998],
    "بورسعيد": [31.2653, 32.3019],
    "السويس": [29.9668, 32.5498],
  };

  var calculationMethod = "muslim_world_league".obs;
  var madhab = "shafi".obs;

  final Map<String, String> calculationMethodsNames = {
    "muslim_world_league": "رابطة العالم الإسلامي",
    "egyptian": "الهيئة العامة المصرية للمساحة",
    "umm_al_qura": "أم القرى (مكة)",
    "karachi": "جامعة العلوم الإسلامية بكراتشي",
    "north_america": "الجمعية الإسلامية لأمريكا الشمالية (ISNA)",
    "dubai": "دبي",
    "kuwait": "الكويت",
    "qatar": "قطر",
    "singapore": "سنغافورة",
    "tehran": "طهران",
    "turkey": "تركيا",
  };

  final Map<String, String> madhabNames = {
    "shafi": "شافعي، مالكي، حنبلي",
    "hanafi": "حنفي (العصر يتأخر)",
  };

  @override
  void onInit() {
    super.onInit();
    fajrOffset.value = box.get('fajrOffset', defaultValue: 0);
    sunriseOffset.value = box.get('sunriseOffset', defaultValue: 0);
    dhuhrOffset.value = box.get('dhuhrOffset', defaultValue: 0);
    asrOffset.value = box.get('asrOffset', defaultValue: 0);
    maghribOffset.value = box.get('maghribOffset', defaultValue: 0);
    ishaOffset.value = box.get('ishaOffset', defaultValue: 0);
// ...

    morningAthkarEnabled.value = box.get('morningEnabled', defaultValue: true);
    morningAthkarHour.value = box.get('morningHour', defaultValue: 7);
    morningAthkarMinute.value = box.get('morningMinute', defaultValue: 0);

    eveningAthkarEnabled.value = box.get('eveningEnabled', defaultValue: true);
    eveningAthkarHour.value = box.get('eveningHour', defaultValue: 17);
    eveningAthkarMinute.value = box.get('eveningMinute', defaultValue: 30);

    quranReminderEnabled.value = box.get('quranReminderEnabled', defaultValue: true);

    useManualLocation.value = box.get('useManualLocation', defaultValue: false);
    isAutomaticLocation.value = !useManualLocation.value;
    manualLocationName.value = box.get('manualCity', defaultValue: "القاهرة");
    manualGovernorate.value = box.get('manualGovernorate', defaultValue: "");

    calculationMethod.value = box.get('calculationMethod', defaultValue: "muslim_world_league");
    madhab.value = box.get('madhab', defaultValue: "shafi");

    fajrAthanEnabled.value = box.get('athan_الفجر', defaultValue: true);
    dhuhrAthanEnabled.value = box.get('athan_الظهر', defaultValue: true);
    asrAthanEnabled.value = box.get('athan_العصر', defaultValue: true);
    maghribAthanEnabled.value = box.get('athan_المغرب', defaultValue: true);
    ishaAthanEnabled.value = box.get('athan_العشاء', defaultValue: true);
  }

  void updateCalculationMethod(String method) {
    calculationMethod.value = method;
    box.put('calculationMethod', method);
    Get.find<PrayerService>().updateSettings();
  }

  void updateMadhab(String m) {
    madhab.value = m;
    box.put('madhab', m);
    Get.find<PrayerService>().updateSettings();
  }

  void saveOffset(String key, int value) {
    box.put(key, value);
    Get.find<PrayerService>().updateSettings();
  }

  void resetOffsets() {
    fajrOffset.value = 0;
    sunriseOffset.value = 0;
    dhuhrOffset.value = 0;
    asrOffset.value = 0;
    maghribOffset.value = 0;
    ishaOffset.value = 0;
    
    box.put('fajrOffset', 0);
    box.put('sunriseOffset', 0);
    box.put('dhuhrOffset', 0);
    box.put('asrOffset', 0);
    box.put('maghribOffset', 0);
    box.put('ishaOffset', 0);
    
    Get.find<PrayerService>().updateSettings();
  }

  void toggleAthkar(bool isMorning, bool value) {
    if (isMorning) {
      morningAthkarEnabled.value = value;
      box.put('morningEnabled', value);
    } else {
      eveningAthkarEnabled.value = value;
      box.put('eveningEnabled', value);
    }
    Get.find<NotificationService>().updateScheduledNotifications();
  }

  void toggleAthanStatus(String name) {
    bool newValue = true;
    if (name == 'الفجر') { fajrAthanEnabled.value = !fajrAthanEnabled.value; newValue = fajrAthanEnabled.value; }
    else if (name == 'الظهر') { dhuhrAthanEnabled.value = !dhuhrAthanEnabled.value; newValue = dhuhrAthanEnabled.value; }
    else if (name == 'العصر') { asrAthanEnabled.value = !asrAthanEnabled.value; newValue = asrAthanEnabled.value; }
    else if (name == 'المغرب') { maghribAthanEnabled.value = !maghribAthanEnabled.value; newValue = maghribAthanEnabled.value; }
    else if (name == 'العشاء') { ishaAthanEnabled.value = !ishaAthanEnabled.value; newValue = ishaAthanEnabled.value; }
    
    box.put('athan_$name', newValue);
    
    Get.snackbar(
      'تنبيه الأذان',
      'تم ${newValue ? 'تفعيل' : 'إيقاف'} صوت أذان $name',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: newValue ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    Get.find<PrayerService>().updateSettings();
  }

  void toggleQuranReminder(bool value) {
    quranReminderEnabled.value = value;
    box.put('quranReminderEnabled', value);
    Get.find<NotificationService>().updateScheduledNotifications();
  }

  void saveAthkarTime(bool isMorning, int hour, int minute) {
    if (isMorning) {
      box.put('morningHour', hour);
      box.put('morningMinute', minute);
      morningAthkarHour.value = hour;
      morningAthkarMinute.value = minute;
    } else {
      box.put('eveningHour', hour);
      box.put('eveningMinute', minute);
      eveningAthkarHour.value = hour;
      eveningAthkarMinute.value = minute;
    }
    Get.find<NotificationService>().updateScheduledNotifications();
  }

  void toggleAutomaticLocation(bool value) {
    isAutomaticLocation.value = value;
    useManualLocation.value = !value;
    box.put('useManualLocation', !value);
    
    if (value) {
      Get.snackbar(
        "تحديد الموقع",
        "جاري محاولة تحديد موقعك تلقائياً...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
    
    Get.find<PrayerService>().updateSettings();
  }

  void toggleManualLocation(bool value) {
    useManualLocation.value = value;
    box.put('useManualLocation', value);
    Get.find<PrayerService>().updateSettings();
  }

  void updateManualCity(String cityName) {
    manualLocationName.value = cityName;
    box.put('manualCity', cityName);
    Get.find<PrayerService>().updateSettings();
  }

  // ✅ تحديث الموقع بالكامل من الخريطة (مدينة + محافظة + إحداثيات)
  void updateManualLocationFull({
    required String cityName,
    required String governorate,
    required double lat,
    required double lng,
  }) {
    manualLocationName.value = cityName;
    manualGovernorate.value = governorate;

    box.put('manualCity', cityName);
    box.put('manualGovernorate', governorate);
    box.put('manualLat', lat);
    box.put('manualLng', lng);
    box.put('useManualLocation', true);

    useManualLocation.value = true;

    Get.find<PrayerService>().updateSettings();
  }

  // ✅ بحث عن مدينة بالاسم وحفظ إحداثياتها تلقائياً
  Future<void> searchCityByName(String query) async {
    if (query.trim().isEmpty) return;

    isSearchingCity.value = true;
    searchError.value = "";

    try {
      await setLocaleIdentifier("ar");
      List<Location> locations = await locationFromAddress(query.trim());

      if (locations.isEmpty) {
        await setLocaleIdentifier("en");
        locations = await locationFromAddress(query.trim());
      }

      if (locations.isNotEmpty) {
        final loc = locations.first;
        box.put('manualCity', query.trim());
        box.put('manualLat', loc.latitude);
        box.put('manualLng', loc.longitude);
        manualLocationName.value = query.trim();
        Get.find<PrayerService>().updateSettings();
        searchError.value = "";
      } else {
        searchError.value = "لم يتم العثور على هذه المدينة";
      }
    } catch (e) {
      searchError.value = "تعذر البحث، تحقق من الاتصال بالإنترنت";
    } finally {
      isSearchingCity.value = false;
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final hijriDate = HijriCalendar.now();
    final meladiDate = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: 'Cairo',
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateCard(context, hijriDate, meladiDate),
          const SizedBox(height: 8),

          const SettingSectionHeader(title: "مواقيت الصلاة"),
          _buildCard([
            _buildSwitchTileSimple(
              "تحديد الموقع تلقائياً",
              controller.isAutomaticLocation,
              Icons.gps_fixed_rounded,
              Colors.blue,
              controller,
              onChanged: (v) => controller.toggleAutomaticLocation(v),
            ),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(
              title: "تعديل مواقيت الصلاة",
              subtitle: "ضبط الدقائق يدوياً لكل صلاة",
              icon: Icons.access_time_filled_rounded,
              iconColor: Colors.orange,
              onTap: () => context.push(AppRouter.prayerSettings),
            ),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(
              title: "اتجاه القبلة",
              subtitle: "البوصلة لتحديد اتجاه الكعبة",
              icon: Icons.explore_rounded,
              iconColor: Colors.green,
              onTap: () => context.push(AppRouter.qibla),
            ),
          ]),

          const SettingSectionHeader(title: "تنبيهات الأذكار"),
          Obx(() => _buildCard([
            _buildSwitchTile("أذكار الصباح", controller.morningAthkarEnabled, Icons.wb_sunny_rounded, Colors.amber, controller, true),
            if (controller.morningAthkarEnabled.value)
              _buildTimeTile(context, "توقيت أذكار الصباح", true, controller),
            const Divider(height: 1, indent: 50),
            _buildSwitchTile("أذكار المساء", controller.eveningAthkarEnabled, Icons.nightlight_round, Colors.indigo, controller, false),
            if (controller.eveningAthkarEnabled.value)
              _buildTimeTile(context, "توقيت أذكار المساء", false, controller),
          ])),

          const SettingSectionHeader(title: "المصحف والختمات"),
          _buildCard([
            _buildSwitchTileSimple("تذكير الورد اليومي", controller.quranReminderEnabled, Icons.menu_book_rounded, Colors.green, controller),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(
                title: "الفواصل",
                icon: Icons.bookmarks_rounded,
                iconColor: Colors.blue,
                onTap: () {
                  final lastPage = controller.box.get('last_quran_page', defaultValue: 1);
                  context.push('${AppRouter.mushaf}/$lastPage');
                }
            ),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(
                title: "آيات مفضلة",
                icon: Icons.stars_rounded,
                iconColor: Colors.amber,
                onTap: () {
                  context.push(AppRouter.quranHome);
                }
            ),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(title: "بدء ختمة جديدة", icon: Icons.auto_stories_rounded, iconColor: Colors.teal, onTap: () => context.push(AppRouter.khatmah)),
          ]),

          const SettingSectionHeader(title: "عن غِراس"),
          _buildCard([
            _buildSettingTile(
                title: "دعم التطبيق",
                subtitle: "ساهم في استمرار وتطوير المشروع",
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                onTap: () => SupportDialog.show(context)
            ),
            const Divider(height: 1, indent: 50),
            _buildSettingTile(
                title: "شارك التطبيق",
                icon: Icons.share_rounded,
                iconColor: Colors.blue,
                onTap: () {
                  Share.share(
                    "حمّل تطبيق ${AppStrings.appName} الآن.. صدقة جارية في جيبك، مواقيت صلاة، قرآن، وأذكار بدون إعلانات.\n\n"
                        "رابط التحميل: ${AppStrings.appStoreLink}",
                  );
                }
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              "غراس - الإصدار 1.0.0",
              style: TextStyle(color: AppColors.textGrey.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildManualLocationSection(BuildContext context, SettingsController controller) {
    final TextEditingController searchController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20),

        // المدينة المختارة حالياً
        Obx(() => ListTile(
          leading: const Icon(Icons.location_on_rounded, color: AppColors.primary),
          title: const Text("المدينة الحالية", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          trailing: Text(
            controller.manualLocationName.value,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        )),

        const Divider(height: 1, indent: 20),

        // حقل البحث اليدوي
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "ابحث عن أي مدينة في العالم...",
                    hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  ),
                  onSubmitted: (v) => controller.searchCityByName(v),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => controller.isSearchingCity.value
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
                  : ElevatedButton(
                onPressed: () => controller.searchCityByName(searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  elevation: 0,
                ),
                child: const Text("بحث", style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
              )),
            ],
          ),
        ),

        // رسالة الخطأ
        Obx(() => controller.searchError.value.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(
                controller.searchError.value,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        )
            : const SizedBox.shrink()),

        const Divider(height: 16, indent: 20),

        // المدن المحفوظة (اختيار سريع)
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
          child: const Text(
            "اختيار سريع",
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.egyptianCities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cityName = controller.egyptianCities.keys.elementAt(index);
              return Obx(() {
                final isSelected = controller.manualLocationName.value == cityName;
                return GestureDetector(
                  onTap: () => controller.updateManualCity(cityName),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cityName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }


  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDateCard(BuildContext context, HijriCalendar hijri, DateTime meladi) {
    final meladiStr = intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(meladi);
    final hijriStr = "${_toArabicNumbers(hijri.hDay.toString())} ${_getArabicHijriMonth(hijri.hMonth)} ${_toArabicNumbers(hijri.hYear.toString())} هـ";

    return InkWell(
      onTap: () => context.push(AppRouter.calendar),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.prayerCardGrad2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/zikrback.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            hijriStr,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        meladiStr,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600
                        )
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "عرض التقويم الكامل",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  String _getArabicHijriMonth(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة'
    ];
    return months[month - 1];
  }

  Widget _buildSettingTile({required String title, String? subtitle, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile(String title, RxBool val, IconData icon, Color color, SettingsController controller, bool isMorning) {
    return Obx(() => SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)
      ),
      value: val.value,
      activeColor: AppColors.primary,
      onChanged: (v) => controller.toggleAthkar(isMorning, v),
    ));
  }

  Widget _buildSwitchTileSimple(String title, RxBool val, IconData icon, Color color, SettingsController controller, {ValueChanged<bool>? onChanged}) {
    return Obx(() => SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)
      ),
      value: val.value,
      activeColor: AppColors.primary,
      onChanged: onChanged ?? (v) => controller.toggleQuranReminder(v),
    ));
  }

  Widget _buildTimeTile(BuildContext context, String title, bool isMorning, SettingsController controller) {
    return Obx(() {
      final h = isMorning ? controller.morningAthkarHour.value : controller.eveningAthkarHour.value;
      final m = isMorning ? controller.morningAthkarMinute.value : controller.eveningAthkarMinute.value;
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final amPm = h >= 12 ? "م" : "ص";

      return ListTile(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: h, minute: m),
          );
          if (time != null) {
            controller.saveAthkarTime(isMorning, time.hour, time.minute);
          }
        },
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${_toArabicNumbers(hour.toString().padLeft(2, '0'))}:${_toArabicNumbers(m.toString().padLeft(2, '0'))} $amPm",
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
      );
    });
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.green.withOpacity(0.1),
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
              "غِراس تطبيق صدقة جارية، دعمك لنا يساعدنا على الاستمرار في تطويره وإضافة مميزات جديدة.",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildSupportOption(
              icon: Icons.phone_android_rounded,
              title: "فودافون كاش",
              subtitle: "01070753890",
              color: Colors.red,
              onCopy: () {
                Clipboard.setData(const ClipboardData(text: "01070753890"));
                Get.snackbar(
                  "تم النسخ",
                  "تم نسخ رقم فودافون كاش",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(15),
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق", style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
            onPressed: onCopy,
          )
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر المدينة", style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: controller.egyptianCities.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final cityName = controller.egyptianCities.keys.elementAt(index);
                    return ListTile(
                      title: Text(cityName, style: const TextStyle(fontFamily: 'Cairo')),
                      onTap: () {
                        controller.updateManualCity(cityName);
                        Navigator.pop(context);
                      },
                      trailing: controller.manualLocationName.value == cityName
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
