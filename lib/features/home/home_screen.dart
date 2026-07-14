import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_paths.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/coach_message_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final roadmap = ref.watch(roadmapProvider).valueOrNull;
    final coachAsync = ref.watch(coachMessageProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    final mission = roadmap?.todaysMission;
    final completion = roadmap?.completionPercent ?? 0;
    final streak = profile?.currentStreak ?? 0;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppUtils.greeting(),
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              profile?.displayName ??
                                  profile?.identityGoal ??
                                  'Champion',
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        StreakBadge(streak: streak),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Goal Card
                    _GoalCard(
                      goal: profile?.identityGoal ?? 'Your Goal',
                      motivation: profile?.motivation,
                      completion: completion,
                    ).animate().fadeIn().slideY(begin: 0.05),

                    const SizedBox(height: AppSpacing.md),

                    // AI Coach Message
                    coachAsync.when(
                      data: (coach) => CoachMessageCard(
                        message: coach.message,
                        type: coach.type,
                      ),
                      loading: () => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, __) => const CoachMessageCard(
                        message:
                            'Ready to make today count? Your mission awaits.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Today's Mission
                    Text(
                      'Today\'s Mission',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      onTap: mission != null && !mission.isCompleted
                          ? () async {
                              await ref
                                  .read(roadmapProvider.notifier)
                                  .completeMission(mission.id);
                              if (context.mounted) {
                                context.showSnackBar('Mission completed! +50 XP 🎉');
                              }
                            }
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            mission?.isCompleted == true
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: mission?.isCompleted == true
                                ? AppColors.success
                                : AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission?.title ?? 'Loading mission...',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: mission?.isCompleted == true
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (mission?.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    mission!.description!,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1.6,
                      children: [
                        _QuickAction(
                          icon: Icons.timer_outlined,
                          label: 'Focus Session',
                          color: AppColors.primary,
                          onTap: () => context.push(RoutePaths.focus),
                        ),
                        _QuickAction(
                          icon: Icons.chat_outlined,
                          label: 'Ask AI Coach',
                          color: AppColors.secondary,
                          onTap: () => context.push(RoutePaths.chat),
                        ),
                        _QuickAction(
                          icon: Icons.check_circle_outline,
                          label: 'Check-in',
                          color: AppColors.warning,
                          onTap: () => context.push(RoutePaths.accountability),
                        ),
                        _QuickAction(
                          icon: Icons.map_outlined,
                          label: 'My Roadmap',
                          color: AppColors.info,
                          onTap: () => context.push(RoutePaths.roadmap),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Progress overview
                    analyticsAsync.when(
                      data: (analytics) => Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Success Probability',
                              value: '${analytics.successProbability.toInt()}%',
                              icon: Icons.trending_up,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: StatCard(
                              label: 'Consistency',
                              value:
                                  '${analytics.consistencyPercent.toInt()}%',
                              icon: Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.completion,
    this.motivation,
  });

  final String goal;
  final double completion;
  final String? motivation;

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
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Becoming',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (motivation != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '"$motivation"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            ProgressRing(
              percent: completion,
              size: 80,
              strokeWidth: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
