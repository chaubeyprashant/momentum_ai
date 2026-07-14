import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accountability.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../repositories/repositories.dart';
import '../services/ai/ai_service.dart';
import '../services/storage/hive_service.dart';

// Services
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService.instance);

final aiServiceProvider = Provider<AiService>((ref) => AiService());

// Repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(hive: ref.watch(hiveServiceProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(
    hive: ref.watch(hiveServiceProvider),
    ai: ref.watch(aiServiceProvider),
  );
});

final accountabilityRepositoryProvider =
    Provider<AccountabilityRepository>((ref) {
  return AccountabilityRepository(hive: ref.watch(hiveServiceProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    hive: ref.watch(hiveServiceProvider),
    ai: ref.watch(aiServiceProvider),
  );
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(hive: ref.watch(hiveServiceProvider));
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    hive: ref.watch(hiveServiceProvider),
    ai: ref.watch(aiServiceProvider),
  );
});

// User Profile State
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(ref.watch(userRepositoryProvider));
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final UserRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _repo.getProfile());
  }

  Future<void> save(UserProfile profile) async {
    await _repo.saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    final updated = profile.copyWith(
      onboardingComplete: true,
      createdAt: DateTime.now(),
    );
    await save(updated);
  }
}

// Roadmap State
final roadmapProvider =
    StateNotifierProvider<RoadmapNotifier, AsyncValue<Roadmap?>>((ref) {
  return RoadmapNotifier(ref.watch(goalRepositoryProvider));
});

class RoadmapNotifier extends StateNotifier<AsyncValue<Roadmap?>> {
  RoadmapNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final GoalRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _repo.getRoadmap());
  }

  Future<Roadmap> generate(UserProfile profile) async {
    state = const AsyncValue.loading();
    final roadmap = await _repo.generateRoadmap(profile);
    state = AsyncValue.data(roadmap);
    return roadmap;
  }

  Future<void> completeMission(String missionId) async {
    final updated = await _repo.completeMission(missionId);
    state = AsyncValue.data(updated);
  }
}

// Analytics State
final analyticsProvider =
    FutureProvider<AnalyticsSnapshot>((ref) async {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) {
    return const AnalyticsSnapshot(
      consistencyPercent: 0,
      successProbability: 50,
      goalCompletionPercent: 0,
      averageDailyHours: 0,
      focusScore: 0,
      currentStreak: 0,
      recoveryScore: 100,
      missedDays: 0,
      weeklyTrend: [0, 0, 0, 0, 0, 0, 0],
      monthlyTrend: [],
    );
  }
  return ref.watch(analyticsRepositoryProvider).getSnapshot(profile);
});

// Coach Message State
final coachMessageProvider =
    FutureProvider<CoachMessage>((ref) async {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) {
    return CoachMessage(
      id: '0',
      message: 'Welcome to Ascend AI. Let\'s begin your transformation.',
      type: CoachMessageType.motivation,
      timestamp: DateTime.now(),
    );
  }

  final accountability = ref.watch(accountabilityRepositoryProvider);
  final records = await accountability.getRecords();
  final analytics = await ref.watch(analyticsRepositoryProvider).getSnapshot(profile);
  final ai = ref.watch(aiServiceProvider);

  return ai.generateCoachMessage(
    profile: profile,
    analytics: analytics,
    skippedYesterday: accountability.skippedYesterday(records),
    daysBehind: _calculateDaysBehind(profile, records),
  );
});

int _calculateDaysBehind(UserProfile profile, List<AccountabilityRecord> records) {
  final expectedDays =
      DateTime.now().difference(profile.createdAt ?? DateTime.now()).inDays;
  final completed =
      records.where((r) => r.status == MissionStatus.yes).length;
  return (expectedDays - completed).clamp(0, 365);
}

// Habits State
final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitsNotifier(ref.watch(habitRepositoryProvider));
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final HabitRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _repo.getHabits());
  }

  Future<void> toggle(String habitId) async {
    await _repo.toggleHabit(habitId);
    await load();
  }
}

// Onboarding draft state
final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, UserProfile?>((ref) {
  return OnboardingDraftNotifier();
});

class OnboardingDraftNotifier extends StateNotifier<UserProfile?> {
  OnboardingDraftNotifier() : super(null);

  void update(UserProfile profile) => state = profile;

  void reset() => state = null;
}
