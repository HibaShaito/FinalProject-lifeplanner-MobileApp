import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // ─── Timezone setup ─────────────────────────────
    tz.initializeTimeZones();
    final String tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    // ─── Plugin initialization ──────────────────────
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_calendar_today'),
    );
    await _plugin.initialize(settings);

    // ─── Channel creation ───────────────────────────
    const androidChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Your task reminders',
      importance: Importance.max,
      playSound: false, // Disable sound here
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // ─── Request notification permissions ────────────
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }

      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final canScheduleExactAlarms =
          await androidPlugin?.canScheduleExactNotifications();
      if (canScheduleExactAlarms == false) {
        await androidPlugin?.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final location = tz.getLocation(await FlutterTimezone.getLocalTimezone());
    final tzDate = tz.TZDateTime.from(scheduledDate, location);

    debugPrint('''Scheduling notification:
  - Local time: ${tzDate.toLocal()}
  - UTC time: ${tzDate.toUtc()}
  - Timezone: ${location.name}''');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Your task reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false, // Disable sound for individual notification
          icon: 'ic_stat_calendar_today',
          largeIcon: const DrawableResourceAndroidBitmap(
            'ic_launcher_foreground',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
