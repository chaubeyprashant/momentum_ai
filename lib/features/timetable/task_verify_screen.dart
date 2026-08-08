import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_error_utils.dart';
import '../../core/utils/app_logger.dart';
import '../../models/gamification.dart';
import '../../models/scheduled_task.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/achievements_grid.dart';

class TaskVerifyScreen extends ConsumerStatefulWidget {
  const TaskVerifyScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskVerifyScreen> createState() => _TaskVerifyScreenState();
}

class _TaskVerifyScreenState extends ConsumerState<TaskVerifyScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _isVerifying = false;
  bool _isCompleting = false;

  void _showRewards(GamificationResult result) {
    if (!result.hasRewards) return;
    showGamificationReward(
      context,
      xpEarned: result.xpEarned,
      leveledUp: result.leveledUp,
      newLevel: result.newLevel,
      achievements: result.newAchievements,
      messages: result.messages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(timetableProvider).valueOrNull ?? [];
    final task = tasks.cast<ScheduledTask?>().firstWhere(
          (t) => t?.id == widget.taskId,
          orElse: () => null,
        );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Task')),
        body: const Center(child: Text('Task not found')),
      );
    }

    final isVerified = task.status == TaskStatus.verified;
    final canSnap = task.canSnapNow;
    final canComplete = task.canMarkComplete;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Task')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (!task.hasStarted && !isVerified) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 18,
                          color: AppColors.warning.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            task.availabilityMessage,
                            style: TextStyle(
                              color: AppColors.warning.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isVerified) ...[
            FilledButton.icon(
              onPressed: canComplete && !_isCompleting
                  ? () => _markComplete(task)
                  : null,
              icon: _isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                canComplete
                    ? 'Mark complete (+${AppConstants.xpTaskComplete} XP)'
                    : task.availabilityMessage,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (canSnap) ...[
            Text(
              'Optional: snap for bonus XP',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Take a photo showing you doing this task for '
              '+${AppConstants.xpPhotoVerifyBonus} bonus XP.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (task.verificationHint != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tip: ${task.verificationHint}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_image!.path),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                      SizedBox(height: AppSpacing.sm),
                      Text('No photo yet'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isVerifying ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isVerifying ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: _image == null || _isVerifying
                  ? null
                  : () => _verify(task),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isVerified
                          ? 'Snap for +${AppConstants.xpPhotoVerifyBonus} XP'
                          : 'Verify snap (+${AppConstants.xpPhotoVerifyBonus} bonus XP)',
                    ),
            ),
          ] else if (task.canSnapForBonus && !task.hasStarted && !isVerified) ...[
            Card(
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.warning.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Snap unlocks ${task.availabilityMessage.toLowerCase()}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (isVerified) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('Task completed!')),
                  ],
                ),
              ),
            ),
          ],
          if (task.status == TaskStatus.rejected &&
              task.verificationFeedback != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: AppColors.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(task.verificationFeedback!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markComplete(ScheduledTask task) async {
    if (!task.canMarkComplete) {
      context.showSnackBar(task.availabilityMessage);
      return;
    }
    setState(() => _isCompleting = true);
    try {
      final result =
          await ref.read(timetableProvider.notifier).markComplete(task.id);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;

      if (result.hasRewards) {
        _showRewards(result);
      } else {
        context.showSnackBar('Marked complete!');
      }
      if (!task.canSnapForBonus || task.photoPath != null) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null) setState(() => _image = image);
  }

  Future<void> _verify(ScheduledTask task) async {
    if (!task.hasStarted) {
      context.showSnackBar(task.availabilityMessage);
      return;
    }
    if (_image == null) return;
    setState(() => _isVerifying = true);

    try {
      final bytes = await _image!.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final savedPath =
          '${dir.path}/task_${task.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(savedPath).writeAsBytes(bytes);

      final result = await ref.read(timetableProvider.notifier).verifyTask(
            taskId: task.id,
            imageBytes: bytes,
            photoPath: savedPath,
          );
      ref.invalidate(userProfileProvider);

      if (!mounted) return;

      if (result.task.status == TaskStatus.verified) {
        if (result.rewards.hasRewards) {
          _showRewards(result.rewards);
        } else {
          context.showSnackBar('Photo verified!');
        }
        context.pop();
      } else {
        context.showSnackBar(
          result.task.verificationFeedback ?? 'Photo not accepted. Try again.',
          isError: true,
        );
      }
    } catch (e, stack) {
      AppLogger.error('TaskVerify', 'Photo verification failed', e, stack);
      if (mounted) {
        context.showSnackBar(
          userFacingAiError(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }
}
