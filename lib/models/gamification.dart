import 'package:equatable/equatable.dart';

import 'habit.dart';

/// Local gamification progress beyond profile XP fields.
class GamificationStats extends Equatable {
  const GamificationStats({
    this.totalCompletions = 0,
    this.lastActiveDate,
    this.lastStreakDate,
    this.dailyBonusDate,
    this.unlockedAchievementIds = const [],
  });

  final int totalCompletions;
  final DateTime? lastActiveDate;
  final DateTime? lastStreakDate;
  final DateTime? dailyBonusDate;
  final List<String> unlockedAchievementIds;

  GamificationStats copyWith({
    int? totalCompletions,
    DateTime? lastActiveDate,
    DateTime? lastStreakDate,
    DateTime? dailyBonusDate,
    List<String>? unlockedAchievementIds,
  }) {
    return GamificationStats(
      totalCompletions: totalCompletions ?? this.totalCompletions,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      dailyBonusDate: dailyBonusDate ?? this.dailyBonusDate,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalCompletions': totalCompletions,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'dailyBonusDate': dailyBonusDate?.toIso8601String(),
        'unlockedAchievementIds': unlockedAchievementIds,
      };

  factory GamificationStats.fromJson(Map<String, dynamic> json) =>
      GamificationStats(
        totalCompletions: json['totalCompletions'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] != null
            ? DateTime.parse(json['lastActiveDate'] as String)
            : null,
        lastStreakDate: json['lastStreakDate'] != null
            ? DateTime.parse(json['lastStreakDate'] as String)
            : null,
        dailyBonusDate: json['dailyBonusDate'] != null
            ? DateTime.parse(json['dailyBonusDate'] as String)
            : null,
        unlockedAchievementIds:
            (json['unlockedAchievementIds'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                const [],
      );

  @override
  List<Object?> get props =>
      [totalCompletions, lastActiveDate, lastStreakDate, dailyBonusDate, unlockedAchievementIds];
}

/// Result of a gamified action for UI feedback.
class GamificationResult extends Equatable {
  const GamificationResult({
    this.xpEarned = 0,
    this.leveledUp = false,
    this.newLevel = 1,
    this.newAchievements = const [],
    this.streakUpdated = false,
    this.currentStreak = 0,
    this.dailyQuestBonus = false,
    this.messages = const [],
  });

  final int xpEarned;
  final bool leveledUp;
  final int newLevel;
  final List<Achievement> newAchievements;
  final bool streakUpdated;
  final int currentStreak;
  final bool dailyQuestBonus;
  final List<String> messages;

  bool get hasRewards =>
      xpEarned > 0 || leveledUp || newAchievements.isNotEmpty;

  @override
  List<Object?> get props =>
      [xpEarned, leveledUp, newLevel, newAchievements, currentStreak];
}

/// Achievement definition with unlock criteria.
class AchievementDefinition extends Equatable {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.xpReward = 100,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;

  Achievement toAchievement({DateTime? unlockedAt}) => Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        xpReward: xpReward,
        unlockedAt: unlockedAt,
      );

  @override
  List<Object?> get props => [id];
}
