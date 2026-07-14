import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/habit.dart';
import '../../providers/app_providers.dart';

class JournalScreen extends HookConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final successController = useTextEditingController();
    final problemsController = useTextEditingController();
    final mood = useState(3);
    final energy = useState(3);
    final isSaving = useState(false);

    Future<void> save() async {
      if (successController.text.trim().isEmpty) {
        context.showSnackBar('Write about today\'s success', isError: true);
        return;
      }
      isSaving.value = true;
      try {
        await ref.read(journalRepositoryProvider).addEntry(
              JournalEntry(
                id: const Uuid().v4(),
                date: DateTime.now(),
                success: successController.text.trim(),
                problems: problemsController.text.trim(),
                mood: mood.value,
                energy: energy.value,
              ),
            );
        if (context.mounted) {
          context.showSnackBar('Journal saved');
          successController.clear();
          problemsController.clear();
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reflection')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Today\'s Success',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: successController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What went well today?',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Problems / Blockers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: problemsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What held you back?',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RatingSlider(
            label: 'Mood',
            value: mood.value,
            onChanged: (v) => mood.value = v,
            emoji: ['😞', '😕', '😐', '🙂', '😄'],
          ),
          const SizedBox(height: AppSpacing.md),
          _RatingSlider(
            label: 'Energy',
            value: energy.value,
            onChanged: (v) => energy.value = v,
            emoji: ['🪫', '🔋', '⚡', '💪', '🚀'],
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: isSaving.value ? null : save,
            child: isSaving.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Reflection'),
          ),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.emoji,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final List<String> emoji;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final rating = i + 1;
                return GestureDetector(
                  onTap: () => onChanged(rating),
                  child: Text(
                    emoji[i],
                    style: TextStyle(
                      fontSize: value == rating ? 32 : 24,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
