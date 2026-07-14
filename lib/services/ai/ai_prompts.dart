import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';

/// System and user prompts for AI interactions.
class AiPrompts {
  AiPrompts._();

  static const roadmapSystem = '''
You are an expert life coach and curriculum designer. Generate a personalized transformation roadmap.
Return ONLY valid JSON with keys: longTermGoal (string), monthlyGoals (array), weeklyGoals (array), dailyTasks (array), todaysMission (string).
Make goals specific, measurable, and identity-based ("becoming X" not just "doing Y").
''';

  static String roadmapUser(UserProfile profile) => '''
Create a roadmap for someone who wants to become: ${profile.identityGoal}
Skill level: ${profile.skillLevel.label}
Deadline: ${profile.deadlineDays} days
Daily hours available: ${profile.hoursPerDay}
Motivation: "${profile.motivation}"
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
    return 'You are an AI life coach. Tone: $tone. Keep messages under 3 sentences. Be identity-focused.';
  }

  static String coachMessage({
    required UserProfile profile,
    required AnalyticsSnapshot analytics,
    required bool skippedYesterday,
    required int daysBehind,
  }) =>
      '''
User goal: ${profile.identityGoal}
Motivation: ${profile.motivation}
Consistency: ${analytics.consistencyPercent.toStringAsFixed(0)}%
Streak: ${analytics.currentStreak} days
Skipped yesterday: $skippedYesterday
Days behind: $daysBehind
Success probability: ${analytics.successProbability.toStringAsFixed(0)}%
Generate a personalized daily coach message.
''';

  static String chatSystem(UserProfile profile, Roadmap? roadmap) => '''
You are an AI coach helping the user become: ${profile.identityGoal}.
Their motivation: "${profile.motivation}"
Skill level: ${profile.skillLevel.label}
Daily hours: ${profile.hoursPerDay}
${roadmap != null ? "Today's mission: ${roadmap.todaysMission?.title ?? 'Not set'}" : ''}
Help with study plans, motivation, quizzes, explanations, and interview prep.
Always tie advice back to their identity transformation.
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
Generate weekly report.
''';
}
