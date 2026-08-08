import 'package:equatable/equatable.dart';

/// User skill level during onboarding.
enum SkillLevel {
  beginner('Just starting'),
  intermediate('Some experience'),
  advanced('Comfortable'),
  professional('Very experienced');

  const SkillLevel(this.label);
  final String label;
}

/// Broad goal category for all audiences.
enum GoalCategory {
  health('Health & Fitness'),
  habits('Daily Habits'),
  learning('Study & Learning'),
  productivity('Productivity'),
  creativity('Creative Pursuits'),
  relationships('Family & Relationships'),
  screenTime('Reduce Screen Time'),
  career('Career & Work'),
  other('Something Else');

  const GoalCategory(this.label);
  final String label;
}

/// Goal deadline options.
enum GoalDeadline {
  oneMonth('1 Month', 30),
  threeMonths('3 Months', 90),
  sixMonths('6 Months', 180),
  oneYear('1 Year', 365),
  twoYears('2 Years', 730),
  custom('Custom', 0);

  const GoalDeadline(this.label, this.days);
  final String label;
  final int days;
}

/// Daily availability options.
enum DailyHours {
  thirtyMin('30 min', 0.5),
  oneHour('1 hr', 1.0),
  twoHours('2 hr', 2.0),
  fourHours('4 hr', 4.0),
  custom('Custom', 0);

  const DailyHours(this.label, this.hours);
  final String label;
  final double hours;
}

/// Mission completion status for accountability.
enum MissionStatus {
  yes('Yes'),
  partial('Partial'),
  no('No');

  const MissionStatus(this.label);
  final String label;
}

/// Skip reason for accountability.
enum SkipReason {
  tooBusy('Too busy'),
  lazy('Lazy'),
  didntKnow('Didn\'t know what to do'),
  health('Health issues'),
  other('Other');

  const SkipReason(this.label);
  final String label;
}

/// AI coach personality types.
enum AiPersonality {
  supportiveCoach('Supportive Coach'),
  strictMentor('Strict Mentor'),
  friendlyBuddy('Friendly Buddy'),
  strategist('Strategist');

  const AiPersonality(this.label);
  final String label;
}

/// User profile and onboarding data.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.identityGoal,
    required this.deadline,
    required this.skillLevel,
    required this.dailyHours,
    required this.motivation,
    this.customDeadlineDays,
    this.customDailyHours,
    this.displayName,
    this.onboardingComplete = false,
    this.createdAt,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.aiPersonality = AiPersonality.supportiveCoach,
    this.goalCategory = GoalCategory.habits,
  });

  final String id;
  final String identityGoal;
  final GoalCategory goalCategory;
  final GoalDeadline deadline;
  final SkillLevel skillLevel;
  final DailyHours dailyHours;
  final String motivation;
  final int? customDeadlineDays;
  final double? customDailyHours;
  final String? displayName;
  final bool onboardingComplete;
  final DateTime? createdAt;
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final AiPersonality aiPersonality;

  int get deadlineDays =>
      deadline == GoalDeadline.custom ? (customDeadlineDays ?? 90) : deadline.days;

  double get hoursPerDay => dailyHours == DailyHours.custom
      ? (customDailyHours ?? 1.0)
      : dailyHours.hours;

  UserProfile copyWith({
    String? id,
    String? identityGoal,
    GoalDeadline? deadline,
    SkillLevel? skillLevel,
    DailyHours? dailyHours,
    String? motivation,
    int? customDeadlineDays,
    double? customDailyHours,
    String? displayName,
    bool? onboardingComplete,
    DateTime? createdAt,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    AiPersonality? aiPersonality,
    GoalCategory? goalCategory,
  }) {
    return UserProfile(
      id: id ?? this.id,
      identityGoal: identityGoal ?? this.identityGoal,
      goalCategory: goalCategory ?? this.goalCategory,
      deadline: deadline ?? this.deadline,
      skillLevel: skillLevel ?? this.skillLevel,
      dailyHours: dailyHours ?? this.dailyHours,
      motivation: motivation ?? this.motivation,
      customDeadlineDays: customDeadlineDays ?? this.customDeadlineDays,
      customDailyHours: customDailyHours ?? this.customDailyHours,
      displayName: displayName ?? this.displayName,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      aiPersonality: aiPersonality ?? this.aiPersonality,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityGoal': identityGoal,
        'deadline': deadline.name,
        'skillLevel': skillLevel.name,
        'dailyHours': dailyHours.name,
        'motivation': motivation,
        'customDeadlineDays': customDeadlineDays,
        'customDailyHours': customDailyHours,
        'displayName': displayName,
        'onboardingComplete': onboardingComplete,
        'createdAt': createdAt?.toIso8601String(),
        'xp': xp,
        'level': level,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'aiPersonality': aiPersonality.name,
        'goalCategory': goalCategory.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        identityGoal: json['identityGoal'] as String,
        deadline: GoalDeadline.values.byName(json['deadline'] as String),
        skillLevel: SkillLevel.values.byName(json['skillLevel'] as String),
        dailyHours: DailyHours.values.byName(json['dailyHours'] as String),
        motivation: json['motivation'] as String,
        customDeadlineDays: json['customDeadlineDays'] as int?,
        customDailyHours: (json['customDailyHours'] as num?)?.toDouble(),
        displayName: json['displayName'] as String?,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        aiPersonality: AiPersonality.values
            .byName(json['aiPersonality'] as String? ?? 'supportiveCoach'),
        goalCategory: GoalCategory.values
            .byName(json['goalCategory'] as String? ?? 'habits'),
      );

  @override
  List<Object?> get props => [id, identityGoal, onboardingComplete];
}
