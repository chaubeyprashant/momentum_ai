import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom habits coming soon')),
              );
            },
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) => ListView.builder(
          padding: AppSpacing.pagePadding,
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Text(habit.icon, style: const TextStyle(fontSize: 28)),
                title: Text(habit.name),
                subtitle: habit.streak > 0
                    ? Text('${habit.streak} day streak')
                    : null,
                trailing: Checkbox(
                  value: habit.isCompletedToday,
                  onChanged: (_) =>
                      ref.read(habitsProvider.notifier).toggle(habit.id),
                ),
                onTap: () =>
                    ref.read(habitsProvider.notifier).toggle(habit.id),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
