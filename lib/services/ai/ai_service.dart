import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/user_profile.dart';
import 'ai_provider.dart';
import 'adaptive_ai_provider.dart';
import 'ai_prompts.dart';

/// High-level AI service orchestrating coach, roadmap, and analytics AI.
class AiService {
  AiService({AiProvider? provider})
      : _provider = provider ?? AdaptiveAiProvider();

  final AiProvider _provider;
  final _uuid = const Uuid();

  AiProvider get provider => _provider;

  /// Generate a personalized roadmap from onboarding data.
  Future<Roadmap> generateRoadmap(UserProfile profile) async {
    try {
      final response = await _provider.complete(
        systemPrompt: AiPrompts.roadmapSystem,
        userPrompt: AiPrompts.roadmapUser(profile),
      );

      final json = _extractJson(response);
      final data = jsonDecode(json) as Map<String, dynamic>;

      return Roadmap(
        id: _uuid.v4(),
        userId: profile.id,
        longTermGoal: _goalFromString(
          data['longTermGoal'] as String? ?? profile.identityGoal,
          GoalPeriod.longTerm,
        ),
        monthlyGoals: _goalsFromList(
          data['monthlyGoals'] as List<dynamic>? ?? [],
          GoalPeriod.monthly,
        ),
        weeklyGoals: _goalsFromList(
          data['weeklyGoals'] as List<dynamic>? ?? [],
          GoalPeriod.weekly,
        ),
        dailyTasks: _goalsFromList(
          data['dailyTasks'] as List<dynamic>? ?? [],
          GoalPeriod.daily,
        ),
        todaysMission: _goalFromString(
          data['todaysMission'] as String? ?? 'Complete today\'s focus session',
          GoalPeriod.mission,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stack) {
      AppLogger.warning('AI', 'Roadmap generation failed, using fallback', e, stack);
      return _fallbackRoadmap(profile);
    }
  }

  /// Generate daily coach message based on user context.
  Future<CoachMessage> generateCoachMessage({
    required UserProfile profile,
    required AnalyticsSnapshot analytics,
    required bool skippedYesterday,
    required int daysBehind,
  }) async {
    final type = _determineMessageType(
      skippedYesterday: skippedYesterday,
      daysBehind: daysBehind,
      consistency: analytics.consistencyPercent,
    );

    final prompt = AiPrompts.coachMessage(
      profile: profile,
      analytics: analytics,
      skippedYesterday: skippedYesterday,
      daysBehind: daysBehind,
    );

    try {
      final message = await _provider.complete(
        systemPrompt: AiPrompts.coachSystem(profile.aiPersonality),
        userPrompt: prompt,
      );
      return CoachMessage(
        id: _uuid.v4(),
        message: message.trim(),
        type: type,
        timestamp: DateTime.now(),
      );
    } catch (e, stack) {
      AppLogger.warning('AI', 'Coach message failed, using fallback (${e.toString().split('\n').first})', e, stack);
      return CoachMessage(
        id: _uuid.v4(),
        message: _fallbackCoachMessage(
          profile: profile,
          type: type,
          skippedYesterday: skippedYesterday,
          daysBehind: daysBehind,
        ),
        type: type,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Adapt roadmap when user skips or progresses faster.
  Future<Roadmap> adaptRoadmap({
    required Roadmap current,
    required UserProfile profile,
    required int consecutiveSkips,
    required double progressRate,
  }) async {
    if (consecutiveSkips >= 3) {
      return _generateRecoveryRoadmap(current, profile);
    }
    if (progressRate > 1.2) {
      return _increaseDifficulty(current, profile);
    }
    return current;
  }

  /// Calculate success probability with AI explanation.
  Future<AnalyticsSnapshot> predictSuccess({
    required UserProfile profile,
    required Roadmap roadmap,
    required List<AccountabilityRecord> records,
    required List<FocusSession> focusSessions,
  }) async {
    final totalDays = profile.deadlineDays;
    final elapsed = DateTime.now().difference(profile.createdAt ?? DateTime.now()).inDays;
    final completedTasks =
        roadmap.dailyTasks.where((t) => t.isCompleted).length;
    final totalTasks = roadmap.dailyTasks.length;
    final consistency = records.isEmpty
        ? 0.0
        : records.where((r) => r.status == MissionStatus.yes).length /
            records.length *
            100;
    final goalCompletion =
        totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;
    final avgHours = focusSessions.isEmpty
        ? profile.hoursPerDay * 0.5
        : focusSessions
                .map((s) => s.durationMinutes / 60.0)
                .reduce((a, b) => a + b) /
            focusSessions.length;
    final missedDays =
        records.where((r) => r.status == MissionStatus.no).length;
    final streak = profile.currentStreak;
    final focusScore = (avgHours / profile.hoursPerDay * 100).clamp(0, 100);
    final timeProgress = elapsed / totalDays;
    final paceRatio = timeProgress > 0 ? goalCompletion / (timeProgress * 100) : 1.0;
    final baseProbability =
        (consistency * 0.3 + goalCompletion * 0.3 + focusScore * 0.2 + (paceRatio * 20)).clamp(0, 100);

    return AnalyticsSnapshot(
      consistencyPercent: consistency,
      successProbability: baseProbability.toDouble(),
      goalCompletionPercent: goalCompletion,
      averageDailyHours: avgHours,
      focusScore: focusScore.toDouble(),
      currentStreak: streak,
      recoveryScore: missedDays > 0 ? (100 - missedDays * 5).clamp(0, 100).toDouble() : 100,
      missedDays: missedDays,
      weeklyTrend: _generateTrend(records, 7),
      monthlyTrend: _generateTrend(records, 30),
      probabilityIfContinues: (baseProbability + 15).clamp(0, 99).toDouble(),
      probabilityIfSkips: (baseProbability - 40).clamp(10, 100).toDouble(),
      predictionExplanation:
          'Based on your ${consistency.toStringAsFixed(0)}% consistency and $streak-day streak, '
          'you have a ${baseProbability.toStringAsFixed(0)}% chance of achieving your goal. '
          '${paceRatio < 0.8 ? "You're behind schedule — focus on today's mission." : "You're on track — keep the momentum!"}',
    );
  }

  /// Chat with AI coach.
  Future<String> chat({
    required UserProfile profile,
    required Roadmap? roadmap,
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': AiPrompts.chatSystem(profile, roadmap),
      },
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      return await _provider.chat(messages: messages);
    } on AppException {
      rethrow;
    } catch (_) {
      return 'I\'m here to help you become ${profile.identityGoal}. What would you like to work on today?';
    }
  }

  /// Weekly AI report summary.
  Future<String> generateWeeklyReport({
    required UserProfile profile,
    required List<AccountabilityRecord> records,
    required List<JournalEntry> journals,
  }) async {
    try {
      return await _provider.complete(
        systemPrompt: AiPrompts.reportSystem,
        userPrompt: AiPrompts.reportUser(profile, records, journals),
      );
    } catch (_) {
      return '## Weekly Report\n\n**Achievements:** You showed up ${records.where((r) => r.status == MissionStatus.yes).length} days this week.\n\n**Focus:** Maintain consistency and tackle your hardest task first each morning.\n\n**Next Week:** Double down on your daily mission — small wins compound.';
    }
  }

  GoalItem _goalFromString(String title, GoalPeriod period) => GoalItem(
        id: _uuid.v4(),
        title: title,
        period: period,
        dueDate: DateTime.now(),
      );

  List<GoalItem> _goalsFromList(List<dynamic> items, GoalPeriod period) =>
      items
          .map((item) => _goalFromString(item.toString(), period))
          .toList();

  String _extractJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return response.substring(start, end + 1);
    }
    return response;
  }

  Roadmap _fallbackRoadmap(UserProfile profile) {
    final goal = profile.identityGoal;
    return Roadmap(
      id: _uuid.v4(),
      userId: profile.id,
      longTermGoal: GoalItem(
        id: _uuid.v4(),
        title: 'Become $goal',
        period: GoalPeriod.longTerm,
      ),
      monthlyGoals: [
        _goalFromString('Build foundational knowledge', GoalPeriod.monthly),
        _goalFromString('Complete first major project', GoalPeriod.monthly),
        _goalFromString('Develop daily learning habit', GoalPeriod.monthly),
      ],
      weeklyGoals: [
        _goalFromString('Study core concepts 5 days', GoalPeriod.weekly),
        _goalFromString('Practice with exercises', GoalPeriod.weekly),
        _goalFromString('Review and reflect', GoalPeriod.weekly),
      ],
      dailyTasks: [
        _goalFromString('${profile.hoursPerDay}hr focused study', GoalPeriod.daily),
        _goalFromString('Practice exercises', GoalPeriod.daily),
        _goalFromString('Evening reflection', GoalPeriod.daily),
      ],
      todaysMission: GoalItem(
        id: _uuid.v4(),
        title: 'Master one new concept in $goal',
        description: 'Focus deeply for ${profile.hoursPerDay} hours',
        period: GoalPeriod.mission,
        dueDate: DateTime.now(),
        estimatedHours: profile.hoursPerDay,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  CoachMessageType _determineMessageType({
    required bool skippedYesterday,
    required int daysBehind,
    required double consistency,
  }) {
    if (consistency >= 80) return CoachMessageType.celebration;
    if (skippedYesterday || daysBehind > 7) return CoachMessageType.warning;
    if (daysBehind > 3) return CoachMessageType.adaptation;
    return CoachMessageType.motivation;
  }

  String _fallbackCoachMessage({
    required UserProfile profile,
    required CoachMessageType type,
    required bool skippedYesterday,
    required int daysBehind,
  }) {
    switch (type) {
      case CoachMessageType.warning:
        return skippedYesterday
            ? 'You skipped yesterday. Remember: "${profile.motivation}". Today is your chance to get back on track.'
            : 'You\'re $daysBehind days behind schedule. Today\'s mission is critical — let\'s close the gap.';
      case CoachMessageType.celebration:
        return 'Incredible work! You\'re proving you ARE becoming ${profile.identityGoal}. Keep this energy going!';
      case CoachMessageType.adaptation:
        return 'I\'ve adjusted your roadmap to help you catch up realistically. Small consistent steps beat heroic sprints.';
      case CoachMessageType.reminder:
        return 'Your mission awaits. ${profile.hoursPerDay} hours today can change your trajectory.';
      case CoachMessageType.motivation:
        return 'Every day you show up, you become more ${profile.identityGoal}. Today\'s mission is your next step.';
    }
  }

  Future<Roadmap> _generateRecoveryRoadmap(Roadmap current, UserProfile profile) async {
    return current.copyWith(
      version: current.version + 1,
      updatedAt: DateTime.now(),
      todaysMission: GoalItem(
        id: _uuid.v4(),
        title: 'Recovery: Light review + 30min focused practice',
        description: 'Ease back in — consistency over intensity',
        period: GoalPeriod.mission,
        dueDate: DateTime.now(),
        estimatedHours: 0.5,
      ),
      weeklyGoals: [
        ...current.weeklyGoals,
        _goalFromString('Recovery week: rebuild habit', GoalPeriod.weekly),
      ],
    );
  }

  Future<Roadmap> _increaseDifficulty(Roadmap current, UserProfile profile) async {
    return current.copyWith(
      version: current.version + 1,
      updatedAt: DateTime.now(),
      todaysMission: GoalItem(
        id: _uuid.v4(),
        title: 'Challenge: Advanced practice + teach-back session',
        description: 'You\'re ahead — time to level up!',
        period: GoalPeriod.mission,
        dueDate: DateTime.now(),
        estimatedHours: profile.hoursPerDay * 1.2,
      ),
    );
  }

  List<double> _generateTrend(List<AccountabilityRecord> records, int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final record = records.cast<AccountabilityRecord?>().firstWhere(
            (r) =>
                r != null &&
                r.date.year == date.year &&
                r.date.month == date.month &&
                r.date.day == date.day,
            orElse: () => null,
          );
      if (record == null) return 0;
      switch (record.status) {
        case MissionStatus.yes:
          return 100;
        case MissionStatus.partial:
          return 50;
        case MissionStatus.no:
          return 0;
      }
    });
  }
}
