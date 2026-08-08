import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_error_utils.dart';
import '../../core/utils/app_logger.dart';
import '../../models/scheduled_task.dart';
import '../../providers/app_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(timetableProvider).valueOrNull ?? [];
    final task = tasks.cast<ScheduledTask?>().firstWhere(
          (t) => t?.id == widget.taskId,
          orElse: () => null,
        );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify Task')),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Snap & Verify')),
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Take a photo showing you doing this task. Gemini AI will verify it.',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                  onPressed: _isVerifying ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isVerifying ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _image == null || _isVerifying ? null : () => _verify(task),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify with AI'),
          ),
          if (task.status == TaskStatus.rejected && task.verificationFeedback != null) ...[
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

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null) setState(() => _image = image);
  }

  Future<void> _verify(ScheduledTask task) async {
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

      if (!mounted) return;

      if (result.status == TaskStatus.verified) {
        context.showSnackBar('Verified! Great job staying on track 🎉');
        context.pop();
      } else {
        context.showSnackBar(
          result.verificationFeedback ?? 'Photo not accepted. Try again.',
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
