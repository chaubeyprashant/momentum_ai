import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/habit.dart';

class QuestHabitCard extends StatelessWidget {
  const QuestHabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    this.showXpReward = true,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final bool showXpReward;

  @override
  Widget build(BuildContext context) {
    final completed = habit.isCompletedToday;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.card,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: completed
                ? Border.all(color: AppColors.success.withValues(alpha: 0.5))
                : null,
            gradient: completed
                ? LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.06),
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(habit.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (habit.streak > 0) ...[
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Text(
                            '${habit.streak} day',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (showXpReward && !completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.xpGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${AppConstants.xpHabitComplete} XP',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.xpGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: 200.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? AppColors.success
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  border: completed
                      ? null
                      : Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : Icons.bolt_rounded,
                  color: completed ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: completed ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(0.98, 0.98),
          duration: 150.ms,
        );
  }
}

class DailyQuestHeader extends StatelessWidget {
  const DailyQuestHeader({
    super.key,
    required this.completed,
    required this.total,
    required this.percent,
  });

  final int completed;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Quests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$completed of $total completed today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                strokeWidth: 5,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                color: percent == 100 ? AppColors.success : AppColors.primary,
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
