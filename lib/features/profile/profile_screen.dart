import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/achievements_grid.dart';
import '../../shared/widgets/xp_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final achievements = ref.watch(achievementsProvider);
    final habits = ref.watch(habitsProvider).valueOrNull ?? [];

    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    final rank = AppUtils.rankTitle(level);

    final activeDays = <DateTime>{};
    for (final habit in habits) {
      for (final date in habit.completedDates) {
        activeDays.add(DateTime(date.year, date.month, date.day));
      }
    }

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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (profile?.displayName ??
                                profile?.identityGoal ??
                                'A')[0]
                            .toUpperCase(),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.xpGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lv $level',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile?.displayName ??
                      profile?.identityGoal ??
                      'Your Journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$rank • $xp XP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.xpGold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          XpProgressBar(level: level, xp: xp),
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
                  label: 'Quests Done',
                  value: '${ref.watch(gamificationServiceProvider).getStats().totalCompletions}',
                  icon: '⚔️',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AchievementsGrid(achievements: achievements),
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
                markerDecoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return activeDays.contains(key) ? [key] : [];
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuTile(
            icon: Icons.repeat,
            title: 'Daily Quests',
            onTap: () => context.push(RoutePaths.habits),
          ),
          _MenuTile(
            icon: Icons.map_outlined,
            title: 'Roadmap',
            onTap: () => context.push(RoutePaths.roadmap),
          ),
          _MenuTile(
            icon: Icons.book_outlined,
            title: 'Journal',
            onTap: () => context.push(RoutePaths.journal),
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
