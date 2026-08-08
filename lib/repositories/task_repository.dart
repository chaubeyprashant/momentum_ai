import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/utils/app_logger.dart';
import '../models/scheduled_task.dart';
import '../models/user_profile.dart';
import '../services/ai/gemini_provider.dart';
import '../services/firebase/user_sync_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/storage/hive_service.dart';

class TaskRepository {
  TaskRepository({
    HiveService? hive,
    GeminiAiProvider? gemini,
    NotificationService? notifications,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _gemini = gemini ?? GeminiAiProvider(),
        _notifications = notifications ?? NotificationService.instance,
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final GeminiAiProvider _gemini;
  final NotificationService _notifications;
  final UserSyncService _sync;
  final _uuid = const Uuid();

  Future<List<ScheduledTask>> getTasks() async => _hive.getScheduledTasks();

  Future<List<ScheduledTask>> getTodayTasks() async {
    final tasks = await getTasks();
    return tasks.where((t) => t.isToday).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<ScheduledTask> addTask(ScheduledTask task) async {
    final notificationId = await _notifications.scheduleTaskReminder(task);
    final missedCallNotificationId =
        await _notifications.scheduleMissedTaskCall(task);
    final withNotification = task.copyWith(
      notificationId: notificationId,
      missedCallNotificationId: missedCallNotificationId,
    );
    final tasks = await getTasks();
    tasks.add(withNotification);
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(withNotification);
    return withNotification;
  }

  Future<ScheduledTask> updateTask(ScheduledTask task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) throw StateError('Task not found');

    final existing = tasks[index];
    await _notifications.cancelTaskNotifications(existing);

    final notificationId = await _notifications.scheduleTaskReminder(task);
    final missedCallNotificationId =
        await _notifications.scheduleMissedTaskCall(task);
    final updated = task.copyWith(
      notificationId: notificationId,
      missedCallNotificationId: missedCallNotificationId,
    );
    tasks[index] = updated;
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(updated);
    return updated;
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    final task = tasks.firstWhere((t) => t.id == taskId);
    await _notifications.cancelTaskNotifications(task);
    tasks.removeWhere((t) => t.id == taskId);
    await _hive.saveScheduledTasks(tasks);
    await _sync.deleteTask(taskId);
  }

  Future<ScheduledTask> markComplete(String taskId) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw StateError('Task not found');

    final task = tasks[index];
    await _notifications.cancelTaskNotifications(task);

    final updated = task.copyWith(
      status: TaskStatus.verified,
      verifiedAt: DateTime.now(),
      verificationFeedback: 'Marked complete',
    );

    tasks[index] = updated;
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(updated);
    return updated;
  }

  Future<ScheduledTask> verifyWithPhoto({
    required String taskId,
    required Uint8List imageBytes,
    required String photoPath,
  }) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw StateError('Task not found');

    final task = tasks[index];
    final result = await _gemini.verifyTaskPhoto(
      imageBytes: imageBytes,
      task: task,
    );

    final updated = task.copyWith(
      photoPath: photoPath,
      status: result.verified ? TaskStatus.verified : TaskStatus.rejected,
      verificationFeedback: result.feedback,
      verificationConfidence: result.confidence,
      verifiedAt: DateTime.now(),
    );

    if (result.verified) {
      await _notifications.cancelTaskNotifications(task);
    }

    tasks[index] = updated;
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(updated);
    return updated;
  }

  Future<void> ensureTaskNotifications() async {
    final tasks = await getTasks();
    var changed = false;
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (task.status != TaskStatus.pending && task.status != TaskStatus.missed) {
        continue;
      }
      if (!task.isToday) continue;

      final notificationId = await _notifications.scheduleTaskReminder(task);
      final missedCallNotificationId =
          await _notifications.scheduleMissedTaskCall(task);
      final updated = task.copyWith(
        notificationId: notificationId,
        missedCallNotificationId: missedCallNotificationId,
      );
      if (updated.notificationId != task.notificationId ||
          updated.missedCallNotificationId != task.missedCallNotificationId) {
        tasks[i] = updated;
        changed = true;
      }
    }
    if (changed) {
      await _hive.saveScheduledTasks(tasks);
    }
  }

  Future<void> markMissedTasks() async {
    final tasks = await getTasks();
    var changed = false;
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (task.isOverdue && task.status == TaskStatus.pending) {
        await _notifications.cancelMissedTaskCall(
          task.missedCallNotificationId ??
              task.id.hashCode.abs() % 100000 + 100000,
        );
        tasks[i] = task.copyWith(status: TaskStatus.missed);
        changed = true;
        await _notifications.showMissedTaskCall(task);
      }
    }
    if (changed) {
      await _hive.saveScheduledTasks(tasks);
      await _sync.syncTasks(tasks);
    }
  }

  Future<List<ScheduledTask>> generateFromProfile(UserProfile profile) async {
    AppLogger.info('Timetable', 'Generating timetable for profile ${profile.id}');

    try {
      final items = await _gemini.generateTimetable(
        goal: profile.identityGoal,
        motivation: profile.motivation,
        hoursPerDay: profile.hoursPerDay,
        category: profile.goalCategory.label,
      );

      if (items.isEmpty) {
        throw StateError('AI returned no timetable tasks');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tasks = <ScheduledTask>[];

      for (final item in items) {
        final hour = item['hour'] as int? ?? 9;
        final minute = item['minute'] as int? ?? 0;
        final categoryName = item['category'] as String? ?? 'other';
        final category = TaskCategory.values.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => TaskCategory.other,
        );

        final title = item['title'] as String? ?? 'Task';
        final task = ScheduledTask(
          id: _uuid.v4(),
          title: title,
          description: item['description'] as String?,
          scheduledAt: today.add(Duration(hours: hour, minutes: minute)),
          durationMinutes: item['durationMinutes'] as int? ?? 30,
          category: category,
          verificationHint: item['verificationHint'] as String?,
          requiresPhotoVerification: ScheduledTask.shouldRequirePhoto(
            category: category,
            title: title,
          ),
        );
        tasks.add(await addTask(task));
      }

      AppLogger.info('Timetable', 'Saved ${tasks.length} scheduled tasks');
      return tasks;
    } catch (e, stack) {
      AppLogger.error('Timetable', 'generateFromProfile failed', e, stack);
      rethrow;
    }
  }

  double todayCompletionRate(List<ScheduledTask> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.status == TaskStatus.verified).length;
    return done / tasks.length * 100;
  }
}
