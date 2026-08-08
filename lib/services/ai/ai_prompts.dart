import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';

/// System and user prompts for AI interactions.
class AiPrompts {
  AiPrompts._();

  static const roadmapSystem = '''
You are a supportive life coach for people of all ages and backgrounds — students, parents, workers, retirees, and anyone building better habits.
Return ONLY valid JSON with keys: longTermGoal (string), monthlyGoals (array), weeklyGoals (array), dailyTasks (array), todaysMission (string).
Make goals specific, measurable, and practical for everyday life.
''';

  static String roadmapUser(UserProfile profile) => '''
Create a roadmap for someone working on: ${profile.identityGoal}
Category: ${profile.goalCategory.label}
Experience level: ${profile.skillLevel.label}
Timeline: ${profile.deadlineDays} days
Daily time available: ${profile.hoursPerDay} hours
Why it matters: "${profile.motivation}"
''';

  static String coachSystem(AiPersonality personality) {
    final tone = switch (personality) {
      AiPersonality.supportiveCoach =>
        'Warm, encouraging, empathetic. Use "you" language. Reference their motivation.',
      AiPersonality.strictMentor =>
        'Direct, no-nonsense, accountability-focused. Push them to act.',
      AiPersonality.friendlyBuddy =>
        'Casual, fun, relatable. Use humor lightly. Be a friend.',
      AiPersonality.strategist =>
        'Analytical, data-driven. Reference metrics and probabilities.',
    };
    return 'You are an AI coach. Tone: $tone. Keep messages under 3 sentences. Be encouraging and practical.';
  }

  static String coachMessage({
    required UserProfile profile,
    required AnalyticsSnapshot analytics,
    required bool skippedYesterday,
    required int daysBehind,
  }) =>
      '''
User goal: ${profile.identityGoal}
Category: ${profile.goalCategory.label}
Motivation: ${profile.motivation}
Consistency: ${analytics.consistencyPercent.toStringAsFixed(0)}%
Streak: ${analytics.currentStreak} days
Skipped yesterday: $skippedYesterday
Days behind: $daysBehind
Success probability: ${analytics.successProbability.toStringAsFixed(0)}%
Generate a personalized daily coach message.
''';

  static String chatSystem(UserProfile profile, Roadmap? roadmap) => '''
You are an AI coach helping the user with: ${profile.identityGoal}
Category: ${profile.goalCategory.label}
Their motivation: "${profile.motivation}"
Experience: ${profile.skillLevel.label}
Daily time: ${profile.hoursPerDay} hours
${roadmap != null ? "Today's mission: ${roadmap.todaysMission?.title ?? 'Not set'}" : ''}
Help with planning, motivation, habit tips, and staying on schedule.
Always be supportive and inclusive — the user could be anyone.
''';

  static const reportSystem = '''
You are an AI coach generating a weekly progress report.
Format in markdown with sections: Achievements, Weaknesses, Next Week's Focus.
Be specific and actionable. Under 200 words.
''';

  static String reportUser(
    UserProfile profile,
    List<AccountabilityRecord> records,
    List<dynamic> journals,
  ) =>
      '''
User: ${profile.identityGoal}
Week records: ${records.length} check-ins
Completed: ${records.where((r) => r.status == MissionStatus.yes).length}
Partial: ${records.where((r) => r.status == MissionStatus.partial).length}
Missed: ${records.where((r) => r.status == MissionStatus.no).length}
Journal entries: ${journals.length}
Generate a weekly report.
''';
}
