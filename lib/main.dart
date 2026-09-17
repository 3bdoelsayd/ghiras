import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/utils/simple_bloc_observer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/helpers/hive_initializer.dart';
import 'features/quran/logic/mushaf_controller.dart';
import 'features/quran/data/page_surah_map.dart';
import 'core/services/prayer_service.dart';
import 'core/services/notification_service.dart';
import 'features/quran/logic/player_bar_bloc/player_bar_bloc.dart';
import 'features/quran/logic/player_bloc/player_bloc_bloc.dart';
import 'features/quran/logic/quran_page_player/quran_page_player_bloc.dart';
import 'features/quran/logic/quran_download_controller.dart';
import 'core/services/sleep_timer_service.dart';

import 'features/quran/data/quran_database_service.dart';

// ✅ تعريف الـ instances لضمان تهيئتها بعد الـ Background Init
AudioPlayer get audioPlayer => Get.find<AudioPlayer>();
late PlayerBarBloc playerbarBloc;
late PlayerBlocBloc playerPageBloc;
late QuranPagePlayerBloc quranPagePlayerBloc;

void main() async {
  // 1. ضمان استقرار المحرك
  WidgetsFlutterBinding.ensureInitialized();

  // تفعيل ميزة العرض حتى حافة الشاشة (Edge-to-Edge) برمجياً
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // تهيئة تنسيق التاريخ للغة العربية لمنع أخطاء الـ intl
  await initializeDateFormatting('ar', null);

  // 2. تهيئة Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await initHiveValues();

  // 3. تهيئة سريعة للـ Blocs وتسجيل الخدمات الأساسية فوراً
  playerbarBloc = PlayerBarBloc();
  playerPageBloc = PlayerBlocBloc();
  quranPagePlayerBloc = QuranPagePlayerBloc();
  Bloc.observer = SimpleBlocObserver();

  // تسجيل الخدمات
  final notificationService = Get.put(NotificationService(), permanent: true);
  
  // ننتظر تهيئة الإشعارات والمنطقة الزمنية
  await notificationService.init();

  if (!Get.isRegistered<PrayerService>()) {
    Get.put(PrayerService(), permanent: true);
  }
  if (!Get.isRegistered<AudioPlayer>()) {
    Get.put(AudioPlayer(), permanent: true);
  }

  if (!Get.isRegistered<MushafController>()) {
    Get.put(MushafController(), permanent: true);
  }
  if (!Get.isRegistered<QuranDownloadController>()) {
    Get.put(QuranDownloadController(), permanent: true);
  }
  if (!Get.isRegistered<SleepTimerService>()) {
    Get.put(SleepTimerService(), permanent: true);
  }
  
  PageSurahMap.getFullMap();

  // 4. تشغيل التطبيق (كان مفقوداً في التعديل السابق)
  runApp(const GhirasApp());
}

class GhirasApp extends StatelessWidget {
  const GhirasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: playerbarBloc),
        BlocProvider.value(value: playerPageBloc),
        BlocProvider.value(value: quranPagePlayerBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return GetMaterialApp.router(
            title: 'غِراس',
            theme: AppTheme.lightTheme,
            routerDelegate: AppRouter.router.routerDelegate,
            routeInformationParser: AppRouter.router.routeInformationParser,
            routeInformationProvider: AppRouter.router.routeInformationProvider,
            backButtonDispatcher: AppRouter.router.backButtonDispatcher,
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
          );
        },
      ),
    );
  }
}
