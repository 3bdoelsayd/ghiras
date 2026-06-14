import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/splash_screen.dart';
import '../../features/ghiras/ghiras_screen.dart';
import '../../features/prayer/prayer_screen.dart';
import '../../features/athkar/athkar_screen.dart';
import '../../features/quran/quran_home_screen.dart';
import '../../features/quran/mushaf_reader.dart';
import '../../features/khatmah/views/khatmah_screen.dart';
import '../../features/tasbeeh/views/tasbeeh_screen.dart';
import '../../features/main_layout.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/prayer_settings_screen.dart';
import '../../features/qibla/qibla_screen.dart';
import '../../features/prayer/location_picker_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/quran/views/reciters_page.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String home = '/';
  static const String ghiras = '/ghiras';
  static const String prayer = '/prayer';
  static const String locationPicker = '/location-picker';
  static const String athkar = '/athkar';
  static const String quranHome = '/quran';
  static const String mushaf = '/mushaf';
  static const String reciters = '/reciters';
  static const String khatmah = '/khatmah';
  static const String tasbeeh = '/tasbeeh';
  static const String settings = '/settings';
  static const String prayerSettings = '/prayer-settings';
  static const String qibla = '/qibla';
  static const String calendar = '/calendar';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: prayerSettings,
        builder: (context, state) => const PrayerSettingsScreen(),
      ),
      GoRoute(
        path: qibla,
        builder: (context, state) => const QiblaScreen(),
      ),
      GoRoute(
        path: calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: ghiras,
        builder: (context, state) => const GhirasScreen(),
      ),
      GoRoute(
        path: prayer,
        builder: (context, state) => const PrayerScreen(),
      ),
      GoRoute(
        path: locationPicker,
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: athkar,
        builder: (context, state) => const AthkarScreen(),
      ),
      GoRoute(
        path: quranHome,
        builder: (context, state) => const QuranHomeScreen(),
      ),
      GoRoute(
        path: reciters,
        builder: (context, state) => const RecitersPage(),
      ),
      GoRoute(
        path: khatmah,
        builder: (context, state) => const KhatmahScreen(),
      ),
      GoRoute(
        path: tasbeeh,
        builder: (context, state) => const TasbeehScreen(),
      ),

      // ✅ /mushaf بدون رقم — يفتح من الصفحة 1
      GoRoute(
        path: mushaf,
        builder: (context, state) => const MushafReader(initialPage: 1),
      ),

      // ✅ /mushaf/50 مع رقم صفحة
      GoRoute(
        path: '$mushaf/:page',
        builder: (context, state) {
          final pageStr = state.pathParameters['page'] ?? '1';
          final page = int.tryParse(pageStr) ?? 1;
          final clampedPage = page.clamp(1, 604);
          return MushafReader(initialPage: clampedPage);
        },
      ),
    ],
  );
}