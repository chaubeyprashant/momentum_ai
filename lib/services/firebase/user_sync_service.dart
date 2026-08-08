import '../../core/utils/app_logger.dart';
import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/scheduled_task.dart';
import '../../models/screen_time.dart';
import '../../models/user_profile.dart';
import '../storage/hive_service.dart';
import 'firestore_service.dart';

/// Syncs user data between Hive (local cache) and Firestore (cloud).
class UserSyncService {
  UserSyncService({
    HiveService? hive,
    FirestoreService? firestore,
  })  : _hive = hive ?? HiveService.instance,
        _firestore = firestore ?? FirestoreService();

  final HiveService _hive;
  final FirestoreService _firestore;

  bool get canSync => _firestore.isAvailable;

  /// Pull all user data from Firestore into local Hive cache.
  Future<void> pullFromCloud() async {
    if (!canSync) return;

    try {
      final results = await Future.wait([
        _firestore.getUserProfile(),
        _firestore.getRoadmap(),
        _firestore.getTasks(),
        _firestore.getHabits(),
        _firestore.getAccountabilityRecords(),
        _firestore.getJournalEntries(),
        _firestore.getFocusSessions(),
        _firestore.getScreenTime(),
      ]);

      final profile = results[0] as UserProfile?;
      final roadmap = results[1] as Roadmap?;
      final tasks = results[2] as List<ScheduledTask>;
      final habits = results[3] as List<Habit>;
      final accountability = results[4] as List<AccountabilityRecord>;
      final journal = results[5] as List<JournalEntry>;
      final focus = results[6] as List<FocusSession>;
      final screenTime = results[7] as ({ScreenTimeGoal? goal, List<ScreenTimeLog> logs});

      if (profile != null) await _hive.saveUserProfile(profile);
      if (roadmap != null) await _hive.saveRoadmap(roadmap);
      if (tasks.isNotEmpty) await _hive.saveScheduledTasks(tasks);
      if (habits.isNotEmpty) await _hive.saveHabits(habits);
      if (accountability.isNotEmpty) {
        await _hive.saveAccountabilityRecords(accountability);
      }
      if (journal.isNotEmpty) await _hive.saveJournalEntries(journal);
      if (focus.isNotEmpty) await _hive.saveFocusSessions(focus);
      if (screenTime.goal != null) {
        await _hive.saveScreenTimeGoal(screenTime.goal!);
      }
      if (screenTime.logs.isNotEmpty) {
        await _hive.saveScreenTimeLogs(screenTime.logs);
      }

      AppLogger.info('Firestore', 'Pulled user data from cloud');
    } catch (e, stack) {
      AppLogger.error('Firestore', 'pullFromCloud failed', e, stack);
    }
  }

  /// Push all local data to Firestore.
  Future<void> pushToCloud() async {
    if (!canSync) return;

    try {
      final profile = _hive.getUserProfile();
      if (profile != null) await _firestore.saveUserProfile(profile);

      final roadmap = _hive.getRoadmap();
      if (roadmap != null) await _firestore.saveRoadmap(roadmap);

      final tasks = _hive.getScheduledTasks();
      if (tasks.isNotEmpty) await _firestore.saveTasks(tasks);

      final habits = _hive.getHabits();
      if (habits.isNotEmpty) await _firestore.saveHabits(habits);

      final accountability = _hive.getAccountabilityRecords();
      if (accountability.isNotEmpty) {
        await _firestore.saveAccountabilityRecords(accountability);
      }

      final journal = _hive.getJournalEntries();
      if (journal.isNotEmpty) await _firestore.saveJournalEntries(journal);

      final focus = _hive.getFocusSessions();
      if (focus.isNotEmpty) await _firestore.saveFocusSessions(focus);

      await _firestore.saveScreenTime(
        goal: _hive.getScreenTimeGoal(),
        logs: _hive.getScreenTimeLogs(),
      );

      AppLogger.info('Firestore', 'Pushed user data to cloud');
    } catch (e, stack) {
      AppLogger.error('Firestore', 'pushToCloud failed', e, stack);
    }
  }

  Future<void> syncProfile(UserProfile profile) async {
    if (!canSync) return;
    try {
      await _firestore.saveUserProfile(profile);
    } catch (e) {
      _firestore.logError('syncProfile', e);
    }
  }

  Future<void> syncRoadmap(Roadmap roadmap) async {
    if (!canSync) return;
    try {
      await _firestore.saveRoadmap(roadmap);
    } catch (e) {
      _firestore.logError('syncRoadmap', e);
    }
  }

  Future<void> syncTasks(List<ScheduledTask> tasks) async {
    if (!canSync) return;
    try {
      await _firestore.saveTasks(tasks);
    } catch (e) {
      _firestore.logError('syncTasks', e);
    }
  }

  Future<void> syncTask(ScheduledTask task) async {
    if (!canSync) return;
    try {
      await _firestore.saveTask(task);
    } catch (e) {
      _firestore.logError('syncTask', e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (!canSync) return;
    try {
      await _firestore.deleteTask(taskId);
    } catch (e) {
      _firestore.logError('deleteTask', e);
    }
  }

  Future<void> syncHabits(List<Habit> habits) async {
    if (!canSync) return;
    try {
      await _firestore.saveHabits(habits);
    } catch (e) {
      _firestore.logError('syncHabits', e);
    }
  }

  Future<void> syncAccountability(List<AccountabilityRecord> records) async {
    if (!canSync) return;
    try {
      await _firestore.saveAccountabilityRecords(records);
    } catch (e) {
      _firestore.logError('syncAccountability', e);
    }
  }

  Future<void> syncJournal(List<JournalEntry> entries) async {
    if (!canSync) return;
    try {
      await _firestore.saveJournalEntries(entries);
    } catch (e) {
      _firestore.logError('syncJournal', e);
    }
  }

  Future<void> syncFocusSessions(List<FocusSession> sessions) async {
    if (!canSync) return;
    try {
      await _firestore.saveFocusSessions(sessions);
    } catch (e) {
      _firestore.logError('syncFocusSessions', e);
    }
  }

  Future<void> syncScreenTime({
    required ScreenTimeGoal goal,
    required List<ScreenTimeLog> logs,
  }) async {
    if (!canSync) return;
    try {
      await _firestore.saveScreenTime(goal: goal, logs: logs);
    } catch (e) {
      _firestore.logError('syncScreenTime', e);
    }
  }

  Future<void> deleteCloudData() async {
    if (!canSync) return;
    await _firestore.deleteAllUserData();
  }
}
