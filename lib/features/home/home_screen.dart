import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/utils/app_router.dart';
import '../khatmah/logic/khatmah_controller.dart';
import '../main_layout.dart';
import '../quran/logic/mushaf_controller.dart';
import '../../core/constants/app_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  PrayerTimes? _prayerTimes;
  Timer? _timer;
  String _timeUntilNext = '';
  String _locationName = 'جاري تحديد الموقع...';
  late Box _settingsBox;
  bool _showAllFeatures = false;

  late AnimationController _headerAnimController;
  late AnimationController _cardAnimController;
  late AnimationController _featuresAnimController;

  late int _randomSurah;
  late int _randomVerse;
  String _randomHadith = '';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    if (!Get.isRegistered<KhatmahController>()) {
      Get.put(KhatmahController());
    }

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _featuresAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initDefaultPrayers();
    _initLocationAndPrayers();
    _startTimer();
    _refreshRandomContent();

    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimController.forward();
      Future.delayed(const Duration(milliseconds: 200), () => _cardAnimController.forward());
      Future.delayed(const Duration(milliseconds: 400), () => _featuresAnimController.forward());
    });
  }

  void _initDefaultPrayers() {
    final cairoCoords = Coordinates(30.0444, 31.2357);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    _prayerTimes = PrayerTimes.today(cairoCoords, params);
    _locationName = 'القاهرة (افتراضي)';
    _updateCountdown();
  }

  void _refreshRandomContent() {
    setState(() {
      _randomSurah = Random().nextInt(114) + 1;
      _randomVerse = Random().nextInt(quran.getVerseCount(_randomSurah)) + 1;
      _randomHadith = AppData.zikrNotfications[Random().nextInt(AppData.zikrNotfications.length)];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    _featuresAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerTimes != null) {
        _updateCountdown();
      }
    });
  }

  Future<void> _initLocationAndPrayers() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final cairoCoords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 3),
          );
          if (mounted) {
            setState(() {
              _prayerTimes = PrayerTimes.today(Coordinates(position.latitude, position.longitude), params);
              _locationName = 'موقعك الحالي';
              _updateCountdown();
            });
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _prayerTimes = PrayerTimes.today(cairoCoords, params);
          _locationName = 'القاهرة (افتراضي)';
          _updateCountdown();
        });
      }
    } catch (e) {
      final cairoCoords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.muslim_world_league.getParameters();
      if (mounted) {
        setState(() {
          _prayerTimes = PrayerTimes.today(cairoCoords, params);
          _locationName = 'القاهرة (افتراضي)';
          _updateCountdown();
        });
      }
    }
  }

  void _updateCountdown() {
    if (_prayerTimes == null) return;
    final now = DateTime.now();
    final nextPrayer = _prayerTimes!.nextPrayer();
    DateTime nextTime;

    if (nextPrayer == Prayer.none) {
      nextTime = _prayerTimes!.fajr.add(const Duration(days: 1));
    } else {
      nextTime = _prayerTimes!.timeForPrayer(nextPrayer)!;
    }

    final diff = nextTime.difference(now);
    if (diff.isNegative) {
      _initLocationAndPrayers();
      return;
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    setState(() {
      _timeUntilNext = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      case Prayer.sunrise: return 'الشروق';
      default: return 'الفجر';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC9A84C).withValues(alpha: 0.08),
                    const Color(0xFFC9A84C).withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ),
          ..._buildDecorativeParticles(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAnimatedHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildGreetingSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildPrayerCardWithLocation(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: _buildSectionTitle('ورد اليوم', ''),
                  ),
                ),
                _buildKhatmahCard(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: _buildSectionTitle('محتوى يومي', ''),
                  ),
                ),
                _buildDailyContentCards(),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeParticles() {
    return [
      Positioned(top: 120, left: 30, child: _particle(6, AppColors.primary.withValues(alpha: 0.15))),
      Positioned(top: 280, right: 40, child: _particle(4, const Color(0xFFC9A84C).withValues(alpha: 0.2))),
      Positioned(top: 450, left: 60, child: _particle(5, AppColors.primary.withValues(alpha: 0.1))),
      Positioned(top: 600, right: 50, child: _particle(3, const Color(0xFFC9A84C).withValues(alpha: 0.15))),
    ];
  }

  Widget _particle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildAnimatedHeader() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      expandedHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _headerAnimController,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
                .animate(CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 32),
                      const SizedBox(width: 12),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          fontFamily: 'Cairo',
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.settings),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.settings_outlined, color: Color(0xFF2C3E50), size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    final greeting = (hour >= 5 && hour < 12)
        ? 'صباح النور ☀️'
        : (hour >= 12 && hour < 17)
        ? 'طاب يومك 🌤️'
        : 'مساء الخير 🌙';

    return FadeTransition(
      opacity: _headerAnimController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السلام عليكم ورحمة الله',
            style: TextStyle(
              color: const Color(0xFF7F8C8D),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            greeting,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCardWithLocation() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _cardAnimController,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
              .animate(CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutCubic)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _prayerTimes == null
                ? _buildPrayerCardSkeleton()
                : _buildPrayerCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCardSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildPrayerCardContent() {
    final nextPrayer = _prayerTimes!.nextPrayer();
    final prayerName = _getPrayerName(nextPrayer);
    final prayerTime = nextPrayer == Prayer.none
        ? _prayerTimes!.fajr
        : _prayerTimes!.timeForPrayer(nextPrayer)!;
    final timeString = intl.DateFormat.jm('ar').format(prayerTime);

    final prayers = [
      {'name': 'الفجر', 'time': _prayerTimes!.fajr},
      {'name': 'الظهر', 'time': _prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': _prayerTimes!.asr},
      {'name': 'المغرب', 'time': _prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': _prayerTimes!.isha},
    ];

    final activePrayerIndex = prayers.indexWhere((p) => p['name'] == prayerName);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5F4A), Color(0xFF0F3D2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22), // ✅ كان 28
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F4A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22), // ✅ كان 28
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12), // ✅ كان 16
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), // ✅ كان 10,5
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFC9A84C),
                              size: 11, // ✅ كان 12
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _locationName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10, // ✅ كان 11
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), // ✅ كان 10,5
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFC9A84C).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              color: Color(0xFFC9A84C),
                              size: 11, // ✅ كان 12
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _timeUntilNext,
                              style: const TextStyle(
                                color: Color(0xFFC9A84C),
                                fontSize: 10, // ✅ كان 11
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // ✅ كان 14
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الصلاة القادمة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10, // ✅ كان 11
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prayerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18, // ✅ كان 22
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'موعد الصلاة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10, // ✅ كان 11
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeString,
                            style: const TextStyle(
                              color: Color(0xFFC9A84C),
                              fontSize: 17, // ✅ كان 20
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // ✅ كان 14
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // ✅ كان 10,10
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: prayers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final prayer = entry.value;
                        final isActive = index == activePrayerIndex;
                        final time = intl.DateFormat('hh:mm a', 'ar').format(prayer['time'] as DateTime);

                        return Column(
                          children: [
                            Container(
                              width: 5, // ✅ كان 6
                              height: 5, // ✅ كان 6
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFFC9A84C)
                                    : Colors.white.withValues(alpha: 0.2),
                                boxShadow: isActive
                                    ? [
                                  BoxShadow(
                                    color: const Color(0xFFC9A84C).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4), // ✅ كان 6
                            Text(
                              prayer['name'] as String,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                fontSize: 9, // ✅ كان 10
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              time,
                              style: TextStyle(
                                color: isActive ? const Color(0xFFC9A84C) : Colors.white.withValues(alpha: 0.4),
                                fontSize: 9, // ✅ كان 10
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKhatmahCard() {
    final khatmahController = Get.find<KhatmahController>();
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _featuresAnimController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() {
            // مراقبة عدد الختمات لضمان التفاعل
            final int khatmatCount = khatmahController.khatmat.length;
            
            if (khatmatCount == 0) {
              return GestureDetector(
                onTap: () => context.push(AppRouter.khatmah),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E8B57), Color(0xFF1A5F4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A5F4A).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 38),
                      const SizedBox(height: 8),
                      const Text(
                        'لا توجد ختمة نشطة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ابدأ ختمة جديدة الآن',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final activeKhatmah = khatmahController.khatmat.first;

            // حماية إضافية للبيانات
            final int startPage = (activeKhatmah.lastReadPage + 1).clamp(1, 604);
            int targetPage = 604;
            try {
               targetPage = activeKhatmah.targetPageForToday;
            } catch (_) {}
            
            final String khatmahName = activeKhatmah.title;
            final double progress = activeKhatmah.progress;

            String firstVerseOfPage = "";
            String surahName = "";

            try {
              final pageData = quran.getPageData(startPage);
              if (pageData.isNotEmpty) {
                final sNum = pageData.first['surah'] ?? 1;
                final vNum = pageData.first['start'] ?? 1;
                surahName = quran.getSurahNameArabic(sNum);
                firstVerseOfPage = quran.getVerse(sNum, vNum);
              }
            } catch (_) {}

            return GestureDetector(
              onTap: () => context.push(AppRouter.khatmah),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5F4A), Color(0xFF0F3D2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15), 
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A5F4A).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFC9A84C).withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: Color(0xFFC9A84C),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      khatmahName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'من ص $startPage إلى ص $targetPage', 
                                    style: const TextStyle(
                                      color: Color(0xFFC9A84C),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    firstVerseOfPage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'UthmanicHafs13',
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'سورة $surahName', 
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'التقدم: ${(activeKhatmah.progress * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white60, fontSize: 9, fontFamily: 'Cairo'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: activeKhatmah.progress,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                                      minHeight: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C3E50),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllFeatures = !_showAllFeatures;
              });
            },
            child: Text(
              _showAllFeatures ? 'إخفاء' : action,
              style: const TextStyle(
                color: AppColors.primary,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalFeaturesList() {
    final mainLayoutController = Get.find<MainLayoutController>();

    final features = [
      {
        'title': 'القرآن الكريم',
        'icon': Icons.menu_book_rounded,
        'gradient': [const Color(0xFF1A5F4A), const Color(0xFF2E8B57)],
        'lightColor': const Color(0xFFE8F5EE),
        'route': AppRouter.quranHome,
        'isRoute': true,
      },
      {
        'title': 'غِراس الجنة',
        'icon': Icons.local_florist_rounded,
        'gradient': [const Color(0xFF2E8B57), const Color(0xFF52B788)],
        'lightColor': const Color(0xFFEAF5ED),
        'route': AppRouter.ghiras,
        'isRoute': true,
        'special': true,
      },
      {
        'title': 'الختمات',
        'icon': Icons.task_alt_rounded,
        'gradient': [const Color(0xFF006D77), const Color(0xFF009BA8)],
        'lightColor': const Color(0xFFE0F4F5),
        'route': AppRouter.khatmah,
        'isRoute': true,
      },
      {
        'title': 'الأذكار',
        'icon': Icons.flare_rounded,
        'gradient': [const Color(0xFFE07B00), const Color(0xFFFFAB40)],
        'lightColor': const Color(0xFFFFF3E0),
        'route': AppRouter.athkar,
        'isRoute': true,
      },
      {
        'title': 'المسبحة',
        'icon': Icons.fingerprint_rounded,
        'gradient': [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
        'lightColor': const Color(0xFFEFF6FF),
        'route': '',
        'isRoute': false,
        'index': 2,
      },
      {
        'title': 'المواقيت',
        'icon': Icons.access_time_filled_rounded,
        'gradient': [const Color(0xFF4338CA), const Color(0xFF818CF8)],
        'lightColor': const Color(0xFFEEF2FF),
        'route': '',
        'isRoute': false,
        'index': 1,
      },
      {
        'title': 'القراء',
        'icon': Icons.record_voice_over_rounded,
        'gradient': [const Color(0xFF7C3D12), const Color(0xFFC2763A)],
        'lightColor': const Color(0xFFFDF0E6),
        'route': '',
        'isRoute': false,
        'index': 3,
      },
    ];

    final displayFeatures = _showAllFeatures ? features : features.take(4).toList();

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _featuresAnimController,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: _featuresAnimController, curve: Curves.easeOutCubic)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: displayFeatures.length,
              itemBuilder: (context, index) {
                final feature = displayFeatures[index];
                final isSpecial = feature['special'] == true;
                final gradientColors = feature['gradient'] as List<Color>;
                final lightColor = feature['lightColor'] as Color;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (feature['isRoute'] == true) {
                      context.push(feature['route'] as String);
                    } else {
                      mainLayoutController.changeIndex(feature['index'] as int);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: isSpecial ? 0.18 : 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                feature['icon'] as IconData,
                                color: Colors.white,
                                size: 22,
                              ),
                              if (isSpecial)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 6,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSpecial ? FontWeight.w800 : FontWeight.w700,
                            color: const Color(0xFF2C3E50),
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyContentCards() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _featuresAnimController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildDailyCard(
                'آية اليوم',
                quran.getVerse(_randomSurah, _randomVerse),
                'سورة ${quran.getSurahNameArabic(_randomSurah)}',
                Icons.menu_book_rounded,
                const Color(0xFF1A5F4A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard(String title, String content, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => HapticFeedback.lightImpact(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 15),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Share.share('$content\n\n[$subtitle]\nتطبيق ${AppStrings.appName}'),
                            child: Icon(Icons.share_rounded, size: 16, color: color.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: _refreshRandomContent,
                            child: Icon(Icons.refresh_rounded, size: 16, color: color.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: title.contains('آية') ? 15 : 13,
                        height: 1.6,
                        color: const Color(0xFF2C3E50),
                        fontFamily: title.contains('آية') ? 'UthmanicHafs13' : 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.5),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}