import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/route_paths.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_error_utils.dart';
import '../../core/utils/app_logger.dart';
import '../../models/scheduled_task.dart';
import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(timetableProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Generate',
            onPressed: profile == null
                ? null
                : () => _generateTimetable(context, ref, profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyTimetable(
              onGenerate: profile == null
                  ? null
                  : () => _generateTimetable(context, ref, profile),
              onAdd: () => _showAddTaskSheet(context, ref),
            );
          }

          final completed =
              tasks.where((t) => t.status == TaskStatus.verified).length;
          final rate = tasks.isEmpty ? 0.0 : completed / tasks.length * 100;

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Progress',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$completed of ${tasks.length} tasks verified',
                              style: context.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${rate.toInt()}%',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...tasks.map((task) => _TaskTile(task: task)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _TimetableError(
          message: userFacingAiError(e),
          onRetry: profile == null
              ? null
              : () => _generateTimetable(context, ref, profile),
        ),
      ),
    );
  }

  Future<void> _generateTimetable(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    try {
      AppLogger.info('Timetable', 'User requested AI timetable generation');
      if (context.mounted) {
        context.showSnackBar('AI is building your timetable...');
      }
      await ref.read(timetableProvider.notifier).generateFromProfile(profile);
      if (context.mounted) {
        context.showSnackBar('Timetable created! Reminders are set.');
      }
    } catch (e, stack) {
      AppLogger.error('Timetable', 'AI timetable generation failed', e, stack);
      if (context.mounted) {
        context.showSnackBar(
          userFacingAiError(e),
          isError: true,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddTaskSheet(
        onSave: (task) async {
          await ref.read(timetableProvider.notifier).addTask(task);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable({this.onGenerate, required this.onAdd});

  final VoidCallback? onGenerate;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Create your daily timetable',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Schedule tasks, get reminders, and snap photos so AI can verify you\'re staying on track.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (onGenerate != null)
              FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Generate Timetable'),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Task Manually'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimetableError extends StatelessWidget {
  const _TimetableError({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final ScheduledTask task;

  Color _statusColor() => switch (task.status) {
        TaskStatus.verified => AppColors.success,
        TaskStatus.rejected => AppColors.error,
        TaskStatus.missed => AppColors.warning,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.jm().format(task.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor().withValues(alpha: 0.15),
          child: Icon(Icons.access_time, color: _statusColor(), size: 20),
        ),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$time • ${task.durationMinutes} min • ${task.category.label}'),
            if (task.verificationFeedback != null)
              Text(
                task.verificationFeedback!,
                style: TextStyle(
                  color: task.status == TaskStatus.verified
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _trailing(context, ref),
        onTap: task.status == TaskStatus.verified
            ? null
            : () => context.push('${RoutePaths.taskVerify}/${task.id}'),
      ),
    );
  }

  Widget? _trailing(BuildContext context, WidgetRef ref) {
    return switch (task.status) {
      TaskStatus.verified => const Icon(Icons.check_circle, color: AppColors.success),
      TaskStatus.rejected => TextButton(
          onPressed: () => context.push('${RoutePaths.taskVerify}/${task.id}'),
          child: const Text('Retry'),
        ),
      TaskStatus.missed => TextButton(
          onPressed: () => context.push('${RoutePaths.taskVerify}/${task.id}'),
          child: const Text('Snap'),
        ),
      _ => task.requiresPhotoVerification
          ? const Icon(Icons.camera_alt_outlined)
          : null,
    };
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.onSave});

  final Future<void> Function(ScheduledTask task) onSave;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _hintController = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  int _duration = 30;
  TaskCategory _category = TaskCategory.other;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task name'),
          ),
          TextField(
            controller: _hintController,
            decoration: const InputDecoration(
              labelText: 'What should the photo show?',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<TaskCategory>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: TaskCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) setState(() => _time = picked);
                },
                child: Text('Time: ${_time.format(context)}'),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _duration,
                items: [15, 30, 45, 60, 90]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (v) => setState(() => _duration = v ?? 30),
              ),
            ],
          ),
          FilledButton(
            onPressed: () async {
              final now = DateTime.now();
              final scheduled = DateTime(
                now.year,
                now.month,
                now.day,
                _time.hour,
                _time.minute,
              );
              await widget.onSave(
                ScheduledTask(
                  id: const Uuid().v4(),
                  title: _titleController.text.trim(),
                  scheduledAt: scheduled,
                  durationMinutes: _duration,
                  category: _category,
                  verificationHint: _hintController.text.trim().isEmpty
                      ? null
                      : _hintController.text.trim(),
                ),
              );
            },
            child: const Text('Save & Set Reminder'),
          ),
        ],
      ),
    );
  }
}
