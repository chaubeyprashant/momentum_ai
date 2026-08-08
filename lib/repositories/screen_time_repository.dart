import '../models/screen_time.dart';
import '../services/firebase/user_sync_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/storage/hive_service.dart';

class ScreenTimeRepository {
  ScreenTimeRepository({
    HiveService? hive,
    NotificationService? notifications,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _notifications = notifications ?? NotificationService.instance,
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final NotificationService _notifications;
  final UserSyncService _sync;

  Future<ScreenTimeGoal> getGoal() async => _hive.getScreenTimeGoal();

  Future<void> saveGoal(ScreenTimeGoal goal) async {
    await _hive.saveScreenTimeGoal(goal);
    await _syncScreenTime();
  }

  Future<ScreenTimeLog?> getTodayLog() async {
    final logs = await getLogs();
    final now = DateTime.now();
    return logs.cast<ScreenTimeLog?>().firstWhere(
          (l) =>
              l != null &&
              l.date.year == now.year &&
              l.date.month == now.month &&
              l.date.day == now.day,
          orElse: () => null,
        );
  }

  Future<List<ScreenTimeLog>> getLogs() async => _hive.getScreenTimeLogs();

  Future<ScreenTimeLog> logMinutes({
    required int minutes,
    int socialMinutes = 0,
    int entertainmentMinutes = 0,
    String? note,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logs = await getLogs();

    final existingIndex = logs.indexWhere(
      (l) =>
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day,
    );

    final log = ScreenTimeLog(
      date: today,
      minutesUsed: minutes,
      socialMinutes: socialMinutes,
      entertainmentMinutes: entertainmentMinutes,
      isManualEntry: true,
      note: note,
    );

    if (existingIndex >= 0) {
      logs[existingIndex] = log;
    } else {
      logs.add(log);
    }

    await _hive.saveScreenTimeLogs(logs);
    await _syncScreenTime();

    final goal = await getGoal();
    if (goal.enabled && goal.reminderAt80Percent) {
      final threshold = (goal.dailyLimitMinutes * 0.8).round();
      if (minutes >= threshold && minutes < goal.dailyLimitMinutes) {
        await _notifications.showScreenTimeWarning(minutes, goal.dailyLimitMinutes);
      } else if (minutes >= goal.dailyLimitMinutes) {
        await _notifications.showInstantReminder(
          title: 'Screen time limit reached',
          body:
              'You\'ve hit your ${goal.dailyLimitMinutes} minute limit. Put the phone down and do something offline!',
        );
      }
    }

    return log;
  }

  Future<int> getRemainingMinutes() async {
    final goal = await getGoal();
    final today = await getTodayLog();
    final used = today?.minutesUsed ?? 0;
    return (goal.dailyLimitMinutes - used).clamp(0, goal.dailyLimitMinutes);
  }

  Future<void> _syncScreenTime() async {
    await _sync.syncScreenTime(
      goal: _hive.getScreenTimeGoal(),
      logs: _hive.getScreenTimeLogs(),
    );
  }
}
