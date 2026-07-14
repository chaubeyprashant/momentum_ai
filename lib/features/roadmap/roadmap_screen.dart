import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/goal.dart';
import '../../providers/app_providers.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapAsync = ref.watch(roadmapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Roadmap')),
      body: roadmapAsync.when(
        data: (roadmap) {
          if (roadmap == null) {
            return const Center(child: Text('No roadmap yet'));
          }

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              _RoadmapSection(
                title: 'Long-term Goal',
                icon: Icons.flag,
                color: AppColors.primary,
                goals: [roadmap.longTermGoal],
              ),
              _RoadmapSection(
                title: 'Monthly Goals',
                icon: Icons.calendar_month,
                color: AppColors.secondary,
                goals: roadmap.monthlyGoals,
              ),
              _RoadmapSection(
                title: 'Weekly Goals',
                icon: Icons.date_range,
                color: AppColors.info,
                goals: roadmap.weeklyGoals,
              ),
              _RoadmapSection(
                title: 'Daily Tasks',
                icon: Icons.today,
                color: AppColors.warning,
                goals: roadmap.dailyTasks,
              ),
              if (roadmap.todaysMission != null)
                _RoadmapSection(
                  title: 'Today\'s Mission',
                  icon: Icons.rocket_launch,
                  color: AppColors.accent,
                  goals: [roadmap.todaysMission!],
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Roadmap v${roadmap.version} • AI-adapted',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.goals,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<GoalItem> goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...goals.map((goal) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(
                  goal.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: goal.isCompleted ? AppColors.success : color,
                ),
                title: Text(
                  goal.title,
                  style: TextStyle(
                    decoration: goal.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: goal.description != null
                    ? Text(goal.description!)
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {},
                ),
              ),
            )),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
