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
    final withNotification = task.copyWith(notificationId: notificationId);
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

    if (task.notificationId != null) {
      await _notifications.cancelTaskReminder(task.notificationId!);
    }
    final notificationId = await _notifications.scheduleTaskReminder(task);
    final updated = task.copyWith(notificationId: notificationId);
    tasks[index] = updated;
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(updated);
    return updated;
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    final task = tasks.firstWhere((t) => t.id == taskId);
    if (task.notificationId != null) {
      await _notifications.cancelTaskReminder(task.notificationId!);
    }
    tasks.removeWhere((t) => t.id == taskId);
    await _hive.saveScheduledTasks(tasks);
    await _sync.deleteTask(taskId);
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

    tasks[index] = updated;
    await _hive.saveScheduledTasks(tasks);
    await _sync.syncTask(updated);
    return updated;
  }

  Future<void> markMissedTasks() async {
    final tasks = await getTasks();
    var changed = false;
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (task.isOverdue && task.status == TaskStatus.pending) {
        tasks[i] = task.copyWith(status: TaskStatus.missed);
        changed = true;
        await _notifications.showInstantReminder(
          title: 'Missed: ${task.title}',
          body: 'You missed your scheduled task. Snap a photo when you complete it!',
        );
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

        final task = ScheduledTask(
          id: _uuid.v4(),
          title: item['title'] as String? ?? 'Task',
          description: item['description'] as String?,
          scheduledAt: today.add(Duration(hours: hour, minutes: minute)),
          durationMinutes: item['durationMinutes'] as int? ?? 30,
          category: category,
          verificationHint: item['verificationHint'] as String?,
          requiresPhotoVerification: category != TaskCategory.screenBreak,
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
