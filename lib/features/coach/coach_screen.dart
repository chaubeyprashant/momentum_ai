import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/coach_message_card.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final coachAsync = ref.watch(coachMessageProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          coachAsync.when(
            data: (coach) => CoachMessageCard(
              message: coach.message,
              type: coach.type,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const CoachMessageCard(
              message: 'Your coach is ready. Let\'s make today count.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          analyticsAsync.when(
            data: (a) => Column(
              children: [
                _InsightTile(
                  icon: Icons.trending_up,
                  title: 'Success Probability',
                  value: '${a.successProbability.toInt()}%',
                  subtitle: a.predictionExplanation,
                ),
                _InsightTile(
                  icon: Icons.local_fire_department,
                  title: 'Current Streak',
                  value: '${a.currentStreak} days',
                ),
                _InsightTile(
                  icon: Icons.speed,
                  title: 'Recovery Score',
                  value: '${a.recoveryScore.toInt()}%',
                  subtitle: a.missedDays > 0
                      ? '${a.missedDays} missed days detected'
                      : 'Perfect consistency!',
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat with Coach'),
            subtitle: const Text('Ask anything about your journey'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(RoutePaths.chat),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Evening Check-in'),
            subtitle: const Text('Did you complete today\'s mission?'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(RoutePaths.accountability),
          ),
          if (profile?.motivation != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Why',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '"${profile!.motivation}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
