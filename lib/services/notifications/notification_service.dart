import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/scheduled_task.dart';

/// Local notification service for task reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  int _notificationId(ScheduledTask task) =>
      task.notificationId ?? task.id.hashCode.abs() % 100000;

  Future<int> scheduleTaskReminder(ScheduledTask task) async {
    if (!task.reminderEnabled) return _notificationId(task);

    final id = _notificationId(task);
    final scheduled = tz.TZDateTime.from(task.scheduledAt, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return id;
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your daily timetable tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    try {
      await _plugin.zonedSchedule(
        id,
        'Time for: ${task.title}',
        task.requiresPhotoVerification
            ? 'Complete this task and snap a photo for AI verification'
            : task.description ?? 'Your scheduled task is starting now',
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }

    return id;
  }

  Future<void> cancelTaskReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> showInstantReminder({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showScreenTimeWarning(int minutesUsed, int limitMinutes) async {
    await showInstantReminder(
      title: 'Screen time alert',
      body:
          'You\'ve used ${minutesUsed}m of your ${limitMinutes}m daily limit. Take a break!',
    );
  }
}
