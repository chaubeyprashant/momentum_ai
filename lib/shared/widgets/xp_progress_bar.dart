import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_utils.dart';

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.level,
    required this.xp,
    this.compact = false,
  });

  final int level;
  final int xp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = AppUtils.xpProgressPercent(xp, level);
    final current = AppUtils.xpProgressInLevel(xp, level);
    final needed = AppUtils.xpNeededForNextLevel(level);
    final rank = AppUtils.rankTitle(level);

    if (compact) {
      return Row(
        children: [
          _LevelBadge(level: level),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rank,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.xpGold,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '$xp XP',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.xpGold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        AppColors.xpGold.withValues(alpha: 0.15),
                    color: AppColors.xpGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LevelBadge(level: level, large: true),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level • $rank',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '$current / $needed XP to next level',
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
                Text(
                  '$xp XP',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.xpGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.xpGold.withValues(alpha: 0.15),
                color: AppColors.xpGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, this.large = false});

  final int level;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 52.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.xpGold, Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.xpGold.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: large ? 20 : 16,
          ),
        ),
      ),
    );
  }
}
