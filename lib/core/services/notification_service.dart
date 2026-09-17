import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

// معالج خارجي للضغط على الإشعارات في الخلفية (مطلوب لبعض الأنظمة)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  debugPrint("Background notification tapped: ${details.id}");
}

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _settingsBox = Hive.box('settings');
  final _initCompleter = Completer<void>();

  @override
  void onInit() {
    super.onInit();
    // نبدأ التهيئة ولكن لا ننتظرها هنا لأن GetX لا يدعم await في onInit
    _initNotifications();
  }

  Future<void> init() async {
    return _initCompleter.future;
  }

  Future<void> _initNotifications() async {
    if (_initCompleter.isCompleted) return;

    try {
      tz_data.initializeTimeZones();
      
      final String timeZoneName = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 'Africa/Cairo',
      );
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Could not set local timezone: $e");
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {}
    }

    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_reminders', 
      'تذكيرات الأذكار والورد', 
      importance: Importance.max, 
      playSound: true, 
      enableVibration: true,
    );

    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_v8', // النسخة الثامنة لضمان العمل كإشعار عادي
      'الأذان وتنبيهات الصلاة',
      description: 'إشعارات مواقيت الصلاة مع صوت الأذان كامل',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('azan'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(dailyChannel);
    await androidImplementation?.createNotificationChannel(prayerChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 2. طلب الصلاحيات والتحقق من البطارية (فقط للأندرويد، أو بشكل آمن لـ iOS)
    if (Platform.isAndroid) {
      await requestFullPermissions();
      await checkBatteryOptimization();
    } else if (Platform.isIOS) {
      // الصلاحيات تطلب تلقائياً بواسطة DarwinInitializationSettings عند الـ initialize
      // نطلب هنا صلاحية الموقع فقط لضمان عمل مواقيت الصلاة بدقة
      await Permission.locationWhenInUse.request();
    }

    _initCompleter.complete();
    updateScheduledNotifications();
  }

  Future<void> checkBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      Get.defaultDialog(
        title: "تنبيه هام للأذان",
        middleText: "لضمان عمل الأذان في الخلفية، يرجى استثناء التطبيق من 'تحسين البطارية'.",
        textConfirm: "تفعيل الآن",
        textCancel: "لاحقاً",
        confirmTextColor: Colors.white,
        onConfirm: () async {
          Get.back();
          await Permission.ignoreBatteryOptimizations.request();
        },
      );
    }
  }

  Future<void> requestFullPermissions() async {
    if (!Platform.isAndroid) return;
    // 1. صلاحية الإشعارات (لأندرويد 13+)
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }

    // 2. صلاحية التنبيهات الدقيقة (لأندرويد 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final bool? hasPermission = await androidPlugin.canScheduleExactNotifications();
      if (hasPermission == false) {
        // تنبيه المستخدم بضرورة تفعيل المنبهات الدقيقة
        Get.defaultDialog(
          title: "تنبيه هام",
          middleText: "لكي يعمل الأذان في وقته بدقة، يرجى تفعيل خيار 'المنبهات والتذكيرات' للتطبيق من الإعدادات.",
          textConfirm: "ذهاب للإعدادات",
          textCancel: "لاحقاً",
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back();
            await openAppSettings();
          },
        );
      }
    }

    // 3. تجاهل تحسين البطارية
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> updateScheduledNotifications() async {
    // إلغاء التنبيهات الخاصة بالأذكار فقط (IDs 1-4) بدلاً من cancelAll
    await _notificationsPlugin.cancel(1);
    await _notificationsPlugin.cancel(2);
    await _notificationsPlugin.cancel(3);
    await _notificationsPlugin.cancel(4);

    // جلب الإعدادات من Hive
    final bool morningEnabled = _settingsBox.get('morningEnabled', defaultValue: true);
    final bool eveningEnabled = _settingsBox.get('eveningEnabled', defaultValue: true);
    final bool quranEnabled = _settingsBox.get('quranReminderEnabled', defaultValue: true);

    final morningHour = _settingsBox.get('morningHour', defaultValue: 7);
    final morningMinute = _settingsBox.get('morningMinute', defaultValue: 0);
    final eveningHour = _settingsBox.get('eveningHour', defaultValue: 17);
    final eveningMinute = _settingsBox.get('eveningMinute', defaultValue: 30);

    if (morningEnabled) {
      await scheduleDailyNotification(
        id: 1,
        title: 'أذكار الصباح',
        body: 'نور يومك بذكر الله.. حان وقت أذكار الصباح ☀️',
        hour: morningHour,
        minute: morningMinute,
      );
    }

    if (eveningEnabled) {
      await scheduleDailyNotification(
        id: 2,
        title: 'أذكار المساء',
        body: 'حصن نفسك واستعن بالله.. حان وقت أذكار المساء 🌙',
        hour: eveningHour,
        minute: eveningMinute,
      );
    }

    if (quranEnabled) {
      await scheduleDailyNotification(
        id: 3,
        title: 'ورد القرآن اليومي',
        body: 'لا تهجر مصحفك.. خصص وقتاً لوردك اليومي الآن 📖',
        hour: 21,
        minute: 0,
      );
    }
    
    // تذكير بسورة الكهف يوم الجمعة
    await scheduleWeeklyNotification(
      id: 4,
      title: 'سورة الكهف',
      body: 'نورٌ ما بين الجمعتين.. لا تنسَ قراءة سورة الكهف اليوم ✨',
      day: DateTime.friday,
      hour: 10,
      minute: 0,
    );
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayTime(day, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reminders',
          'التذكيرات الأسبوعية',
          channelDescription: 'إشعارات أسبوعية (سورة الكهف)',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfDayTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final timeStr = "${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'م' : 'ص'}";

    await _notificationsPlugin.zonedSchedule(
      id,
      "$title $timeStr",
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'التذكيرات اليومية',
          channelDescription: 'إشعارات يومية للأذكار والورد',
          importance: Importance.max,
          priority: Priority.max,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          showWhen: true,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'instant_notifications',
      'إشعارات فورية',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? sound,
  }) async {
    try {
      // التأكد من أن التاريخ في المستقبل
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_v8',
            'الأذان وتنبيهات الصلاة',
            channelDescription: 'إشعارات مواقيت الصلاة مع صوت الأذان كامل',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('azan'),
            showWhen: true,
            category: AndroidNotificationCategory.event, // تم التغيير لـ event كونه إشعار عادي
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'azan_ios.mp3', // استخدام ملف الصوت المخصص المكون من 15 ثانية والمتوافق مع شروط iOS
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Successfully scheduled notification $id for $tzDate");
    } catch (e) {
      debugPrint("Notification Scheduling Error for ID $id: $e");
    }
  }

  Future<void> showDownloadNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    bool isCompleted = false,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_progress',
      'تحميل السور',
      channelDescription: 'إشعارات تقدم تحميل سور القرآن',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: !isCompleted,
      autoCancel: isCompleted,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
