import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/habit.dart';

/// AI coach message bubble.
class CoachMessageCard extends StatelessWidget {
  const CoachMessageCard({
    super.key,
    required this.message,
    this.type = CoachMessageType.motivation,
  });

  final String message;
  final CoachMessageType type;

  Color get _accentColor => switch (type) {
        CoachMessageType.celebration => AppColors.success,
        CoachMessageType.warning => AppColors.warning,
        CoachMessageType.adaptation => AppColors.info,
        CoachMessageType.reminder => AppColors.primary,
        CoachMessageType.motivation => AppColors.secondary,
      };

  IconData get _icon => switch (type) {
        CoachMessageType.celebration => Icons.celebration,
        CoachMessageType.warning => Icons.warning_amber_rounded,
        CoachMessageType.adaptation => Icons.auto_fix_high,
        CoachMessageType.reminder => Icons.notifications_active,
        CoachMessageType.motivation => Icons.psychology,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accentColor.withValues(alpha: 0.15),
              _accentColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _accentColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Coach',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

/// Primary CTA button with loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Streak fire badge.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.streakFire.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.streakFire.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$streak day streak',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.streakFire,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
