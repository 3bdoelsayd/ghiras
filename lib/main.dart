import 'dart:async';
import 'package:flutter/material.dart';
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

import 'features/quran/data/quran_database_service.dart';

// ✅ تعريف الـ instances لضمان تهيئتها بعد الـ Background Init
AudioPlayer get audioPlayer => Get.find<AudioPlayer>();
late PlayerBarBloc playerbarBloc;
late PlayerBlocBloc playerPageBloc;
late QuranPagePlayerBloc quranPagePlayerBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Hive سريعة جداً وضرورية لبداية التشغيل
  try {
    await Hive.initFlutter();
    await Hive.openBox('settings');
    await initHiveValues();
  } catch (e) {
    debugPrint("Hive Init Error: $e");
  }

  // ✅ تهيئة التنسيقات الزمنية قبل التشغيل لضمان عدم وجود أخطاء في واجهة التاريخ
  try {
    await initializeDateFormatting('ar', null);
  } catch (e) {
    debugPrint("Date Format Init Error: $e");
  }

  // ✅ تنفيذ العمليات الثقيلة والتهيئة
  await _initServicesAsync();
  
  // تهيئة قاعدة بيانات القرآن مبكراً لتسريع الفتح لاحقاً
  QuranDatabaseService.init();

  // ✅ تشغيل التطبيق بعد التهيئة
  runApp(const GhirasApp());
}

Future<void> _initServicesAsync() async {
  // تهيئة الـ Audio Service
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.ghiras.audio',
      androidNotificationChannelName: 'Ghiras Audio Service',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    );
    
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (e) {
    debugPrint("JustAudioBackground Init Error: $e");
  }

  // إنشاء نسخة واحدة فقط من الـ Player
  if (!Get.isRegistered<AudioPlayer>()) {
    Get.put(AudioPlayer(), permanent: true);
  }

  // إنشاء الـ Blocs
  playerbarBloc = PlayerBarBloc();
  playerPageBloc = PlayerBlocBloc();
  quranPagePlayerBloc = QuranPagePlayerBloc();
  Bloc.observer = SimpleBlocObserver();

  // تهيئة الخدمات
  if (!Get.isRegistered<MushafController>()) {
    Get.put(MushafController(), permanent: true);
  }
  if (!Get.isRegistered<NotificationService>()) {
    Get.put(NotificationService(), permanent: true);
  }
  if (!Get.isRegistered<PrayerService>()) {
    Get.put(PrayerService(), permanent: true);
  }
  if (!Get.isRegistered<QuranDownloadController>()) {
    Get.put(QuranDownloadController(), permanent: true);
  }

  PageSurahMap.getFullMap();
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
