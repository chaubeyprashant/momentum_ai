import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/user_profile.dart';
import '../services/ai/ai_service.dart';
import '../services/firebase/user_sync_service.dart';
import '../services/storage/hive_service.dart';

/// User profile repository — Hive cache with Firestore sync.
class UserRepository {
  UserRepository({
    HiveService? hive,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final UserSyncService _sync;

  Future<UserProfile?> getProfile() async => _hive.getUserProfile();

  Future<void> saveProfile(UserProfile profile) async {
    await _hive.saveUserProfile(profile);
    await _sync.syncProfile(profile);
  }

  Future<bool> isOnboardingComplete() async {
    final profile = await getProfile();
    return profile?.onboardingComplete ?? false;
  }
}

/// Goals and roadmap repository.
class GoalRepository {
  GoalRepository({
    HiveService? hive,
    AiService? ai,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _ai = ai ?? AiService(),
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final AiService _ai;
  final UserSyncService _sync;

  Future<Roadmap?> getRoadmap() async => _hive.getRoadmap();

  Future<Roadmap> generateRoadmap(UserProfile profile) async {
    final roadmap = await _ai.generateRoadmap(profile);
    await _hive.saveRoadmap(roadmap);
    await _sync.syncRoadmap(roadmap);
    return roadmap;
  }

  Future<void> saveRoadmap(Roadmap roadmap) async {
    await _hive.saveRoadmap(roadmap);
    await _sync.syncRoadmap(roadmap);
  }

  Future<Roadmap> completeMission(String missionId) async {
    final roadmap = await getRoadmap();
    if (roadmap == null) throw StateError('No roadmap found');

    final updated = roadmap.copyWith(
      todaysMission: roadmap.todaysMission?.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      ),
      dailyTasks: roadmap.dailyTasks.map((t) {
        if (t.id == missionId) {
          return t.copyWith(isCompleted: true, completedAt: DateTime.now());
        }
        return t;
      }).toList(),
      updatedAt: DateTime.now(),
    );
    await saveRoadmap(updated);
    return updated;
  }

  Future<Roadmap> adaptRoadmap({
    required UserProfile profile,
    required int consecutiveSkips,
    required double progressRate,
  }) async {
    final current = await getRoadmap();
    if (current == null) throw StateError('No roadmap found');

    final adapted = await _ai.adaptRoadmap(
      current: current,
      profile: profile,
      consecutiveSkips: consecutiveSkips,
      progressRate: progressRate,
    );
    await saveRoadmap(adapted);
    return adapted;
  }
}

/// Accountability check-in repository.
class AccountabilityRepository {
  AccountabilityRepository({
    HiveService? hive,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final UserSyncService _sync;

  Future<List<AccountabilityRecord>> getRecords() async =>
      _hive.getAccountabilityRecords();

  Future<void> addRecord(AccountabilityRecord record) async {
    final records = await getRecords();
    records.removeWhere(
      (r) =>
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day,
    );
    records.add(record);
    await _hive.saveAccountabilityRecords(records);
    await _sync.syncAccountability(records);
  }

  int getConsecutiveSkips(List<AccountabilityRecord> records) {
    if (records.isEmpty) return 0;
    final sorted = List<AccountabilityRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    var skips = 0;
    for (final record in sorted) {
      if (record.status == MissionStatus.no) {
        skips++;
      } else {
        break;
      }
    }
    return skips;
  }

  bool skippedYesterday(List<AccountabilityRecord> records) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final record = records.cast<AccountabilityRecord?>().firstWhere(
          (r) =>
              r != null &&
              r.date.year == yesterday.year &&
              r.date.month == yesterday.month &&
              r.date.day == yesterday.day,
          orElse: () => null,
        );
    return record?.status == MissionStatus.no;
  }
}

/// Analytics repository powered by AI predictions.
class AnalyticsRepository {
  AnalyticsRepository({HiveService? hive, AiService? ai})
      : _hive = hive ?? HiveService.instance,
        _ai = ai ?? AiService();

  final HiveService _hive;
  final AiService _ai;

  Future<AnalyticsSnapshot> getSnapshot(UserProfile profile) async {
    final roadmap = _hive.getRoadmap();
    final records = _hive.getAccountabilityRecords();
    final sessions = _hive.getFocusSessions();

    return _ai.predictSuccess(
      profile: profile,
      roadmap: roadmap ??
          Roadmap(
            id: '',
            userId: profile.id,
            longTermGoal: GoalItem(
              id: '',
              title: profile.identityGoal,
              period: GoalPeriod.longTerm,
            ),
            monthlyGoals: [],
            weeklyGoals: [],
            dailyTasks: [],
          ),
      records: records,
      focusSessions: sessions,
    );
  }
}

/// Habit tracking repository.
class HabitRepository {
  HabitRepository({
    HiveService? hive,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final UserSyncService _sync;

  Future<List<Habit>> getHabits() async => _hive.getHabits();

  Future<void> toggleHabit(String habitId) async {
    final habits = await getHabits();
    final updated = habits.map((h) {
      if (h.id == habitId) {
        final now = DateTime.now();
        final completed = !h.isCompletedToday;
        return h.copyWith(
          isCompletedToday: completed,
          streak: completed ? h.streak + 1 : h.streak,
          completedDates: completed
              ? [...h.completedDates, now]
              : h.completedDates,
        );
      }
      return h;
    }).toList();
    await _hive.saveHabits(updated);
    await _sync.syncHabits(updated);
  }

  Future<void> resetDailyHabits() async {
    final habits = await getHabits();
    final updated = habits.map((h) => h.copyWith(isCompletedToday: false)).toList();
    await _hive.saveHabits(updated);
    await _sync.syncHabits(updated);
  }
}

/// Journal repository.
class JournalRepository {
  JournalRepository({
    HiveService? hive,
    AiService? ai,
    UserSyncService? sync,
  })  : _hive = hive ?? HiveService.instance,
        _ai = ai ?? AiService(),
        _sync = sync ?? UserSyncService();

  final HiveService _hive;
  final AiService _ai;
  final UserSyncService _sync;

  Future<List<JournalEntry>> getEntries() async => _hive.getJournalEntries();

  Future<void> addEntry(JournalEntry entry) async {
    final entries = await getEntries();
    entries.add(entry);
    await _hive.saveJournalEntries(entries);
    await _sync.syncJournal(entries);
  }

  Future<String> generateWeeklySummary(UserProfile profile) async {
    final entries = await getEntries();
    final records = _hive.getAccountabilityRecords();
    return _ai.generateWeeklyReport(
      profile: profile,
      records: records,
      journals: entries,
    );
  }
}
