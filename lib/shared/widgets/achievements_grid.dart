import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_utils.dart';
import '../../models/habit.dart';

class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({
    super.key,
    required this.achievements,
  });

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _AchievementTile(achievement: achievement);
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Card(
      color: unlocked
          ? AppColors.xpGold.withValues(alpha: 0.08)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 28,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

void showGamificationReward(
  BuildContext context, {
  required int xpEarned,
  required bool leveledUp,
  required int newLevel,
  required List<Achievement> achievements,
  required List<String> messages,
}) {
  if (xpEarned <= 0 && !leveledUp && achievements.isEmpty) return;

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Text(
            leveledUp ? '🎉' : '⚡',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              leveledUp ? 'Level Up!' : 'Quest Complete!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (xpEarned > 0)
            Text(
              '+$xpEarned XP earned',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.xpGold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (leveledUp) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('You reached Level $newLevel!'),
            Text(
              AppUtils.rankTitle(newLevel),
              style: TextStyle(color: AppColors.xpGold.withValues(alpha: 0.9)),
            ),
          ],
          if (achievements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'New achievements:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...achievements.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${a.icon} ${a.title}'),
              ),
            ),
          ],
          if (messages.isNotEmpty && !leveledUp && achievements.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...messages.map((m) => Text(m)),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome!'),
        ),
      ],
    ),
  );
}
