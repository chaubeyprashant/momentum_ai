import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_ai/core/utils/app_utils.dart';
import 'package:momentum_ai/models/user_profile.dart';
import 'package:momentum_ai/services/ai/ai_service.dart';

void main() {
  group('AppUtils', () {
    test('levelFromXp calculates correctly', () {
      expect(AppUtils.levelFromXp(0), 1);
      expect(AppUtils.levelFromXp(100), 1);
      expect(AppUtils.levelFromXp(400), 2);
    });

    test('clampPercent clamps values', () {
      expect(AppUtils.clampPercent(150), 100);
      expect(AppUtils.clampPercent(-10), 0);
      expect(AppUtils.clampPercent(50), 50);
    });
  });

  group('AiService', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService();
    });

    test('generateRoadmap returns valid roadmap', () async {
      const profile = UserProfile(
        id: 'test-user',
        identityGoal: 'AI Engineer',
        deadline: GoalDeadline.threeMonths,
        skillLevel: SkillLevel.beginner,
        dailyHours: DailyHours.oneHour,
        motivation: 'I want to change my career',
      );

      final roadmap = await aiService.generateRoadmap(profile);

      expect(roadmap.userId, 'test-user');
      expect(roadmap.monthlyGoals, isNotEmpty);
      expect(roadmap.todaysMission, isNotNull);
    });

    test('predictSuccess returns analytics snapshot', () async {
      const profile = UserProfile(
        id: 'test-user',
        identityGoal: 'AI Engineer',
        deadline: GoalDeadline.threeMonths,
        skillLevel: SkillLevel.beginner,
        dailyHours: DailyHours.oneHour,
        motivation: 'Career change',
        createdAt: null,
      );

      final snapshot = await aiService.predictSuccess(
        profile: profile,
        roadmap: await aiService.generateRoadmap(profile),
        records: [],
        focusSessions: [],
      );

      expect(snapshot.successProbability, greaterThanOrEqualTo(0));
      expect(snapshot.successProbability, lessThanOrEqualTo(100));
    });
  });

  group('UserProfile', () {
    test('serializes and deserializes', () {
      const profile = UserProfile(
        id: '1',
        identityGoal: 'Software Engineer',
        deadline: GoalDeadline.oneYear,
        skillLevel: SkillLevel.intermediate,
        dailyHours: DailyHours.twoHours,
        motivation: 'Build great products',
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.identityGoal, profile.identityGoal);
      expect(restored.deadline, profile.deadline);
    });
  });
}
