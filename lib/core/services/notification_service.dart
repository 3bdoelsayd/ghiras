import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _settingsBox = Hive.box('settings');

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();
    
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (e) {
      debugPrint("Could not set local timezone: $e");
    }
    
    // طلب كافة الصلاحيات الضرورية لضمان عمل الأذان
    await _requestFullPermissions();

    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_reminders', 
      'تذكيرات الأذكار والورد', 
      importance: Importance.max, 
      playSound: true, 
      enableVibration: true,
    );

    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_v2',
      'الأذان وتنبيهات الصلاة',
      description: 'إشعارات مواقيت الصلاة مع صوت الأذان كامل',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('azan'),
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(dailyChannel);
    await androidImplementation?.createNotificationChannel(prayerChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // يمكن هنا إضافة منطق عند الضغط على الإشعار
      },
    );

    updateScheduledNotifications();
  }

  Future<void> _requestFullPermissions() async {
    // 1. صلاحية الإشعارات (لأندرويد 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. صلاحية التنبيهات الدقيقة (لأندرويد 12+)
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.requestExactAlarmsPermission();

    // 3. تجاهل تحسين البطارية (هام جداً للأذان)
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
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'prayer_v2',
          'الأذان وتنبيهات الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('azan'),
          showWhen: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: sound != null ? '$sound.caf' : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
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
