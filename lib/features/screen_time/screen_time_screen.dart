import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/progress_ring.dart';

class ScreenTimeScreen extends ConsumerWidget {
  const ScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(screenTimeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Screen Time')),
      body: stateAsync.when(
        data: (state) => ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    ProgressRing(
                      percent: state.percentUsed,
                      size: 100,
                      strokeWidth: 10,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.usedMinutes}m used',
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.remainingMinutes}m remaining of ${state.goal.dailyLimitMinutes}m limit',
                            style: context.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Log your screen time',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Track how much time you spend on your phone. We\'ll remind you when you\'re close to your limit.',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [30, 60, 90, 120, 180, 240].map((mins) {
                return ActionChip(
                  label: Text('+$mins min'),
                  onPressed: () => _addMinutes(ref, state.usedMinutes + mins),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Daily limit',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: state.goal.dailyLimitMinutes.toDouble(),
              min: 30,
              max: 480,
              divisions: 15,
              label: '${state.goal.dailyLimitMinutes} min',
              onChanged: (v) => ref
                  .read(screenTimeProvider.notifier)
                  .saveGoal(state.goal.copyWith(dailyLimitMinutes: v.round())),
            ),
            SwitchListTile(
              title: const Text('Screen time alerts'),
              subtitle: const Text('Notify at 80% and when limit is reached'),
              value: state.goal.reminderAt80Percent,
              onChanged: (v) => ref
                  .read(screenTimeProvider.notifier)
                  .saveGoal(state.goal.copyWith(reminderAt80Percent: v)),
            ),
            SwitchListTile(
              title: const Text('Focus mode protection'),
              subtitle: const Text('Remind you to stay off phone during tasks'),
              value: state.goal.blockDuringFocusTasks,
              onChanged: (v) => ref
                  .read(screenTimeProvider.notifier)
                  .saveGoal(state.goal.copyWith(blockDuringFocusTasks: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Tip: Pair screen time limits with timetable tasks. '
                  'Schedule offline activities and verify them with a photo snap!',
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _addMinutes(WidgetRef ref, int total) async {
    await ref.read(screenTimeProvider.notifier).logMinutes(total);
  }
}
