import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _permissionsRequested = false;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Request runtime permissions (Android 13+ notifications, iOS alert/sound).
  /// Safe to call multiple times — only prompts once per install.
  Future<void> ensurePermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    try {
      final android =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      // Exact alarms need SCHEDULE_EXACT_ALARM (manifest added); prompt user.
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    try {
      final ios =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await ensurePermissions();
    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'planner_channel_v2',
          'Planner Reminders',
          channelDescription:
              'Reminders for tasks and expenses with alarm sound',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Re-schedule all future reminders (call after reboot / restore).
  Future<void> rescheduleAll(
      List<({int id, String title, String body, DateTime when})> items) async {
    for (final item in items) {
      if (item.when.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: item.id,
          title: item.title,
          body: item.body,
          scheduledDate: item.when,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
