import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final roadmap = ref.watch(roadmapProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (profile?.identityGoal ?? 'A')[0].toUpperCase(),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile?.identityGoal ?? 'Your Journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Level ${profile?.level ?? 1} • ${profile?.xp ?? 0} XP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.xpGold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  label: 'Streak',
                  value: '${profile?.currentStreak ?? 0}',
                  icon: '🔥',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ProfileStat(
                  label: 'Best Streak',
                  value: '${profile?.longestStreak ?? 0}',
                  icon: '🏆',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ProfileStat(
                  label: 'Progress',
                  value: '${roadmap?.completionPercent.toInt() ?? 0}%',
                  icon: '📈',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: TableCalendar(
              firstDay: DateTime.utc(2024),
              lastDay: DateTime.utc(2030),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuTile(
            icon: Icons.map_outlined,
            title: 'Roadmap',
            onTap: () => context.push(RoutePaths.roadmap),
          ),
          _MenuTile(
            icon: Icons.repeat,
            title: 'Habits',
            onTap: () => context.push(RoutePaths.habits),
          ),
          _MenuTile(
            icon: Icons.book_outlined,
            title: 'Journal',
            onTap: () => context.push(RoutePaths.journal),
          ),
          _MenuTile(
            icon: Icons.image_outlined,
            title: 'Vision Board',
            onTap: () => context.push(RoutePaths.visionBoard),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
