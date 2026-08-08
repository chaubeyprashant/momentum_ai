import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_feedback.dart';
import '../../providers/app_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.improvement;
  int _rating = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      context.showSnackBar('Please write at least 10 characters', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(feedbackServiceProvider).submit(
            category: _category,
            message: message,
            rating: _rating,
          );
      if (!mounted) return;
      context.showSnackBar('Thanks for your feedback!');
      context.pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Could not send feedback. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Help us improve ${AppConstants.appName}',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your feedback shapes what we build next. Tell us what\'s working '
            'and what isn\'t.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('How would you rate the app?', style: context.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('What is this about?', style: context.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: FeedbackCategory.values.map((category) {
              final selected = _category == category;
              return ChoiceChip(
                label: Text(category.label),
                selected: selected,
                onSelected: (_) => setState(() => _category = category),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _messageController,
            maxLines: 6,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Your feedback',
              hintText: _category.hint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Sending...' : 'Submit Feedback'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You can also reach us at ${AppConstants.supportEmail}',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
