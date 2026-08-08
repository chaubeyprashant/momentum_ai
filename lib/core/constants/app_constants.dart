/// Global app constants for HabitCoach AI.
class AppConstants {
  AppConstants._();

  static const String appName = 'HabitCoach AI';
  static const String appTagline = 'Your daily coach for everyone.';
  static const String appVersion = '1.0.1';
  static const String supportEmail = 'habitcoach.ai.support@gmail.com';

  // Hive box names
  static const String userBox = 'user_box';
  static const String goalsBox = 'goals_box';
  static const String habitsBox = 'habits_box';
  static const String journalBox = 'journal_box';
  static const String settingsBox = 'settings_box';
  static const String tasksBox = 'tasks_box';

  // Streak thresholds
  static const int adaptationSkipDays = 3;
  static const int defaultPomodoroMinutes = 25;
  static const int defaultBreakMinutes = 5;

  // XP values
  static const int xpDailyMission = 50;
  static const int xpHabitComplete = 25;
  static const int xpTaskComplete = 15;
  static const int xpPhotoVerifyBonus = 15;
  static const int xpStreakBonus = 10;
  static const int xpFocusSession = 30;

  // AI
  static const String defaultAiPersonality = 'supportive_coach';
}
