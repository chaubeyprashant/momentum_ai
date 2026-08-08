import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/scheduled_task.dart';
import '../storage/hive_service.dart';

/// Local notification service for task reminders and missed-task call alerts.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _taskChannelId = 'task_reminders';
  static const _missedCallChannelId = 'missed_task_calls';

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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _taskChannelId,
        'Task Reminders',
        description: 'Reminders for your daily timetable tasks',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _missedCallChannelId,
        'Missed Task Calls',
        description: 'Urgent reminder calls when you miss a scheduled task',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  bool get missedTaskCallsEnabled =>
      HiveService.instance.getMissedTaskCallsEnabled();

  int _notificationId(ScheduledTask task) =>
      task.notificationId ?? task.id.hashCode.abs() % 100000;

  int _missedCallNotificationId(ScheduledTask task) =>
      task.missedCallNotificationId ?? (_notificationId(task) + 100000);

  NotificationDetails _taskDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          'Task Reminders',
          channelDescription: 'Reminders for your daily timetable tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  NotificationDetails _missedCallDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _missedCallChannelId,
          'Missed Task Calls',
          channelDescription:
              'Urgent reminder calls when you miss a scheduled task',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
          ticker: 'Missed task reminder call',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  Future<int> scheduleTaskReminder(ScheduledTask task) async {
    if (!task.reminderEnabled) return _notificationId(task);

    final id = _notificationId(task);
    final scheduled = tz.TZDateTime.from(task.scheduledAt, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return id;
    }

    try {
      await _plugin.zonedSchedule(
        id,
        'Time for: ${task.title}',
        task.canSnapForBonus
            ? 'Tap to complete. Snap a photo for bonus XP!'
            : task.description ?? 'Tap to mark this task complete when done',
        scheduled,
        _taskDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }

    return id;
  }

  Future<int> scheduleMissedTaskCall(ScheduledTask task) async {
    if (!task.reminderEnabled || !missedTaskCallsEnabled) {
      return _missedCallNotificationId(task);
    }
    if (task.status == TaskStatus.verified || task.status == TaskStatus.skipped) {
      return _missedCallNotificationId(task);
    }

    final id = _missedCallNotificationId(task);
    final deadline = tz.TZDateTime.from(task.deadlineAt, tz.local);

    if (deadline.isBefore(tz.TZDateTime.now(tz.local))) {
      return id;
    }

    try {
      await _plugin.zonedSchedule(
        id,
        'Missed task: ${task.title}',
        'You missed this task. Open HabitCoach to complete it now!',
        deadline,
        _missedCallDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule missed task call: $e');
    }

    return id;
  }

  Future<void> scheduleTaskNotifications(ScheduledTask task) async {
    await scheduleTaskReminder(task);
    await scheduleMissedTaskCall(task);
  }

  Future<void> cancelTaskReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelMissedTaskCall(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelTaskNotifications(ScheduledTask task) async {
    final reminderId = task.notificationId;
    if (reminderId != null) {
      await cancelTaskReminder(reminderId);
    }
    final missedCallId = task.missedCallNotificationId;
    if (missedCallId != null) {
      await cancelMissedTaskCall(missedCallId);
    }
  }

  Future<void> showInstantReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      _taskDetails(),
    );
  }

  Future<void> showMissedTaskCall(ScheduledTask task) async {
    if (!missedTaskCallsEnabled) return;

    await _plugin.show(
      _missedCallNotificationId(task),
      'Reminder call: ${task.title}',
      'You missed this task. Open HabitCoach to complete it now!',
      _missedCallDetails(),
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
