import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hijri/hijri_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/prayer_service.dart';
import '../../core/utils/app_router.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final PrayerService _prayerService = Get.find<PrayerService>();
  Timer? _timer;
  String _timeUntilNext = '';
  final HijriCalendar _hijriDate = HijriCalendar.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final prayerTimes = _prayerService.prayerTimes.value;
    if (prayerTimes == null) return;

    final now = DateTime.now();
    final nextPrayer = prayerTimes.nextPrayer();
    DateTime nextTime;

    if (nextPrayer == Prayer.none) {
      nextTime = prayerTimes.fajr.add(const Duration(days: 1));
    } else {
      nextTime = prayerTimes.timeForPrayer(nextPrayer)!;
    }

    final diff = nextTime.difference(now);
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

  String _formatTime(DateTime time) {
    return intl.DateFormat.jm('ar').format(time);
  }

  String _getArabicHijriDate() {
    final months = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    String day = _toArabicNumbers(_hijriDate.hDay.toString());
    String month = months[_hijriDate.hMonth - 1];
    String year = _toArabicNumbers(_hijriDate.hYear.toString());
    return '$day $month $year هـ';
  }

  String _toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('مواقيت الصلاة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
            Text(
              _getArabicHijriDate(),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Obx(() {
        final prayerTimes = _prayerService.prayerTimes.value;
        if (prayerTimes == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildLocationInfo(),
              const SizedBox(height: 15),
              _buildNextPrayerCard(prayerTimes),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPrayerTimeRow('الفجر', _formatTime(prayerTimes.fajr), prayerTimes.currentPrayer() == Prayer.fajr),
                    _buildPrayerTimeRow('الشروق', _formatTime(prayerTimes.sunrise), prayerTimes.currentPrayer() == Prayer.sunrise),
                    _buildPrayerTimeRow('الظهر', _formatTime(prayerTimes.dhuhr), prayerTimes.currentPrayer() == Prayer.dhuhr),
                    _buildPrayerTimeRow('العصر', _formatTime(prayerTimes.asr), prayerTimes.currentPrayer() == Prayer.asr),
                    _buildPrayerTimeRow('المغرب', _formatTime(prayerTimes.maghrib), prayerTimes.currentPrayer() == Prayer.maghrib),
                    _buildPrayerTimeRow('العشاء', _formatTime(prayerTimes.isha), prayerTimes.currentPrayer() == Prayer.isha),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Obx(() => Text(
              _prayerService.currentCity.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo', 
                fontSize: 14, 
                color: AppColors.primary, 
                fontWeight: FontWeight.w700
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTimes prayerTimes) {
    final next = prayerTimes.nextPrayer();
    final name = _getPrayerName(next);
    final time = next == Prayer.none ? prayerTimes.fajr : prayerTimes.timeForPrayer(next)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.prayerCardGrad2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text('صلاة $name', style: const TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(_formatTime(time), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'متبقي $_timeUntilNext', 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(String name, String time, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isCurrent ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          if (!isCurrent) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isCurrent) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              if (isCurrent) const SizedBox(width: 8),
              Text(name, style: TextStyle(fontSize: 18, fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold, color: AppColors.textDark, fontFamily: 'Cairo')),
            ],
          ),
          Text(time, style: TextStyle(fontSize: 18, fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600, color: AppColors.textDark, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}
