import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/achievements_grid.dart';
import '../../shared/widgets/quest_habit_card.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  Future<void> _toggleHabit(
    BuildContext context,
    WidgetRef ref,
    String habitId,
  ) async {
    final result = await ref.read(habitsProvider.notifier).toggle(habitId);
    await ref.read(userProfileProvider.notifier).load();

    if (!context.mounted) return;

    if (result.hasRewards) {
      showGamificationReward(
        context,
        xpEarned: result.xpEarned,
        leveledUp: result.leveledUp,
        newLevel: result.newLevel,
        achievements: result.newAchievements,
        messages: result.messages,
      );
    } else {
      context.showSnackBar('Quest unchecked');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final gamification = ref.watch(gamificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '⚡ ${profile?.xp ?? 0} XP',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          final completed = habits.where((h) => h.isCompletedToday).length;
          final percent = gamification.dailyQuestProgress(habits);

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              DailyQuestHeader(
                completed: completed,
                total: habits.length,
                percent: percent,
              ),
              const SizedBox(height: AppSpacing.md),
              if (percent == 100)
                Card(
                  color: Colors.green.withValues(alpha: 0.1),
                  child: const ListTile(
                    leading: Text('💎', style: TextStyle(fontSize: 24)),
                    title: Text('Perfect day!'),
                    subtitle: Text(
                      'All quests done — +${AppConstants.xpDailyMission} XP bonus earned',
                    ),
                  ),
                ),
              if (percent == 100) const SizedBox(height: AppSpacing.sm),
              ...habits.map(
                (habit) => QuestHabitCard(
                  habit: habit,
                  onToggle: () => _toggleHabit(context, ref, habit.id),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
