import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/gamification.dart';
import '../../models/habit.dart';
import '../../models/user_profile.dart';
import '../../services/storage/hive_service.dart';

class GamificationService {
  GamificationService({HiveService? hive}) : _hive = hive ?? HiveService.instance;

  final HiveService _hive;

  static const achievements = <AchievementDefinition>[
    AchievementDefinition(
      id: 'first_quest',
      title: 'First Quest',
      description: 'Complete your first daily quest',
      icon: '⚔️',
      xpReward: 50,
    ),
    AchievementDefinition(
      id: 'streak_3',
      title: 'On Fire',
      description: 'Reach a 3-day streak',
      icon: '🔥',
      xpReward: 75,
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: '🛡️',
      xpReward: 150,
    ),
    AchievementDefinition(
      id: 'streak_30',
      title: 'Unstoppable',
      description: 'Hit a 30-day streak',
      icon: '👑',
      xpReward: 500,
    ),
    AchievementDefinition(
      id: 'all_quests',
      title: 'Perfect Day',
      description: 'Complete all quests in one day',
      icon: '💎',
      xpReward: 100,
    ),
    AchievementDefinition(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      icon: '⭐',
      xpReward: 200,
    ),
    AchievementDefinition(
      id: 'level_10',
      title: 'Habit Legend',
      description: 'Reach level 10',
      icon: '🏆',
      xpReward: 400,
    ),
    AchievementDefinition(
      id: 'quests_25',
      title: 'Quest Grinder',
      description: 'Complete 25 quests total',
      icon: '🎯',
      xpReward: 125,
    ),
    AchievementDefinition(
      id: 'quests_100',
      title: 'Centurion',
      description: 'Complete 100 quests total',
      icon: '🗡️',
      xpReward: 300,
    ),
  ];

  GamificationStats getStats() => _hive.getGamificationStats();

  Future<void> saveStats(GamificationStats stats) =>
      _hive.saveGamificationStats(stats);

  List<Achievement> getAllAchievements() {
    final stats = getStats();
    final now = DateTime.now();
    return achievements
        .map(
          (def) => def.toAchievement(
            unlockedAt: stats.unlockedAchievementIds.contains(def.id)
                ? now
                : null,
          ),
        )
        .toList();
  }

  /// Process habit completion and return rewards for UI.
  Future<GamificationResult> processHabitCompletion({
    required UserProfile? profile,
    required List<Habit> habits,
    required bool completed,
  }) async {
    if (profile == null || !completed) {
      return const GamificationResult();
    }

    var stats = getStats();
    final messages = <String>[];
    var xpEarned = AppConstants.xpHabitComplete;
    messages.add('+${AppConstants.xpHabitComplete} XP');

    stats = stats.copyWith(
      totalCompletions: stats.totalCompletions + 1,
      lastActiveDate: DateTime.now(),
    );

    var updatedProfile = profile;
    final today = _dateOnly(DateTime.now());
    final lastStreak = stats.lastStreakDate != null
        ? _dateOnly(stats.lastStreakDate!)
        : null;

    var streakUpdated = false;
    var currentStreak = profile.currentStreak;

    if (lastStreak == null) {
      currentStreak = 1;
      streakUpdated = true;
      stats = stats.copyWith(lastStreakDate: today);
    } else if (lastStreak == today) {
      // Already counted today.
    } else if (lastStreak == today.subtract(const Duration(days: 1))) {
      currentStreak = profile.currentStreak + 1;
      streakUpdated = true;
      stats = stats.copyWith(lastStreakDate: today);
      xpEarned += AppConstants.xpStreakBonus;
      messages.add('+${AppConstants.xpStreakBonus} streak bonus');
    } else {
      currentStreak = 1;
      streakUpdated = true;
      stats = stats.copyWith(lastStreakDate: today);
    }

    if (streakUpdated) {
      updatedProfile = updatedProfile.copyWith(
        currentStreak: currentStreak,
        longestStreak: currentStreak > profile.longestStreak
            ? currentStreak
            : profile.longestStreak,
      );
    }

    final allDone = habits.isNotEmpty && habits.every((h) => h.isCompletedToday);
    var dailyQuestBonus = false;
    final bonusDate = stats.dailyBonusDate != null
        ? _dateOnly(stats.dailyBonusDate!)
        : null;

    if (allDone && bonusDate != today) {
      xpEarned += AppConstants.xpDailyMission;
      dailyQuestBonus = true;
      stats = stats.copyWith(dailyBonusDate: today);
      messages.add('Perfect day! +${AppConstants.xpDailyMission} XP');
    }

    final previousLevel = updatedProfile.level;
    final newXp = updatedProfile.xp + xpEarned;
    final newLevel = AppUtils.levelFromXp(newXp);
    final leveledUp = newLevel > previousLevel;

    updatedProfile = updatedProfile.copyWith(xp: newXp, level: newLevel);
    await _hive.saveUserProfile(updatedProfile);

    final newlyUnlocked = _checkAchievements(
      stats: stats,
      profile: updatedProfile.copyWith(level: newLevel),
      allQuestsDone: allDone,
    );

    for (final achievement in newlyUnlocked) {
      stats = stats.copyWith(
        unlockedAchievementIds: [
          ...stats.unlockedAchievementIds,
          achievement.id,
        ],
      );
      updatedProfile = updatedProfile.copyWith(
        xp: updatedProfile.xp + achievement.xpReward,
      );
      xpEarned += achievement.xpReward;
      messages.add('${achievement.icon} ${achievement.title} unlocked!');
    }

    await _hive.saveUserProfile(updatedProfile);
    await saveStats(stats);

    if (leveledUp) {
      messages.add('Level up! You are now level $newLevel');
    }

    return GamificationResult(
      xpEarned: xpEarned,
      leveledUp: leveledUp,
      newLevel: newLevel,
      newAchievements: newlyUnlocked,
      streakUpdated: streakUpdated,
      currentStreak: currentStreak,
      dailyQuestBonus: dailyQuestBonus,
      messages: messages,
    );
  }

  List<Achievement> _checkAchievements({
    required GamificationStats stats,
    required UserProfile profile,
    required bool allQuestsDone,
  }) {
    final unlocked = <Achievement>[];
    final already = stats.unlockedAchievementIds.toSet();

    bool shouldUnlock(String id, bool condition) {
      return condition && !already.contains(id);
    }

    final checks = <String, bool>{
      'first_quest': stats.totalCompletions >= 1,
      'streak_3': profile.currentStreak >= 3,
      'streak_7': profile.currentStreak >= 7,
      'streak_30': profile.currentStreak >= 30,
      'all_quests': allQuestsDone,
      'level_5': profile.level >= 5,
      'level_10': profile.level >= 10,
      'quests_25': stats.totalCompletions >= 25,
      'quests_100': stats.totalCompletions >= 100,
    };

    for (final def in achievements) {
      if (shouldUnlock(def.id, checks[def.id] ?? false)) {
        unlocked.add(def.toAchievement(unlockedAt: DateTime.now()));
      }
    }

    return unlocked;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int dailyQuestProgress(List<Habit> habits) {
    if (habits.isEmpty) return 0;
    final done = habits.where((h) => h.isCompletedToday).length;
    return ((done / habits.length) * 100).round();
  }

  /// Award XP for completing a scheduled timetable task.
  Future<GamificationResult> processTaskCompletion({
    required UserProfile? profile,
    bool includeBase = true,
    bool includePhotoBonus = false,
  }) async {
    if (profile == null || (!includeBase && !includePhotoBonus)) {
      return const GamificationResult();
    }

    final messages = <String>[];
    var xpEarned = 0;

    if (includeBase) {
      xpEarned += AppConstants.xpTaskComplete;
      messages.add('+${AppConstants.xpTaskComplete} XP');
    }
    if (includePhotoBonus) {
      xpEarned += AppConstants.xpPhotoVerifyBonus;
      messages.add('+${AppConstants.xpPhotoVerifyBonus} snap bonus!');
    }

    var stats = getStats();
    if (includeBase) {
      stats = stats.copyWith(
        totalCompletions: stats.totalCompletions + 1,
        lastActiveDate: DateTime.now(),
      );
    }

    final previousLevel = profile.level;
    final newXp = profile.xp + xpEarned;
    final newLevel = AppUtils.levelFromXp(newXp);
    final leveledUp = newLevel > previousLevel;

    final updatedProfile = profile.copyWith(xp: newXp, level: newLevel);
    await _hive.saveUserProfile(updatedProfile);
    await saveStats(stats);

    if (leveledUp) {
      messages.add('Level up! You are now level $newLevel');
    }

    return GamificationResult(
      xpEarned: xpEarned,
      leveledUp: leveledUp,
      newLevel: newLevel,
      messages: messages,
    );
  }
}
