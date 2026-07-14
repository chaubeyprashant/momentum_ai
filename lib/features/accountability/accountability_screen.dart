import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/accountability.dart';
import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/coach_message_card.dart';

class AccountabilityScreen extends HookConsumerWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState<MissionStatus?>(null);
    final skipReason = useState<SkipReason?>(null);
    final note = useTextEditingController();
    final isSubmitting = useState(false);

    Future<void> submit() async {
      if (status.value == null) return;
      if (status.value == MissionStatus.no && skipReason.value == null) {
        context.showSnackBar('Please select a reason', isError: true);
        return;
      }

      isSubmitting.value = true;
      try {
        final record = AccountabilityRecord(
          id: const Uuid().v4(),
          date: DateTime.now(),
          status: status.value!,
          skipReason: skipReason.value,
          note: note.text.isNotEmpty ? note.text : null,
        );

        await ref
            .read(accountabilityRepositoryProvider)
            .addRecord(record);

        // Trigger adaptation if 3+ consecutive skips
        final records =
            await ref.read(accountabilityRepositoryProvider).getRecords();
        final skips = ref
            .read(accountabilityRepositoryProvider)
            .getConsecutiveSkips(records);

        if (skips >= 3) {
          final profile = ref.read(userProfileProvider).valueOrNull;
          if (profile != null) {
            await ref.read(goalRepositoryProvider).adaptRoadmap(
                  profile: profile,
                  consecutiveSkips: skips,
                  progressRate: 1.0,
                );
            ref.invalidate(roadmapProvider);
            if (context.mounted) {
              context.showSnackBar(
                'AI adapted your roadmap to help you recover',
              );
            }
          }
        }

        if (context.mounted) {
          context.showSnackBar('Check-in recorded. Keep going!');
          Navigator.of(context).pop();
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Evening Check-in')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Did you complete today\'s mission?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...MissionStatus.values.map((s) => _StatusOption(
                status: s,
                selected: status.value == s,
                onTap: () => status.value = s,
              )),
          if (status.value == MissionStatus.no) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Why not?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...SkipReason.values.map((r) => _ReasonOption(
                  reason: r,
                  selected: skipReason.value == r,
                  onTap: () => skipReason.value = r,
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any notes? (optional)',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Submit Check-in',
            isLoading: isSubmitting.value,
            onPressed: status.value != null ? submit : null,
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final MissionStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      MissionStatus.yes => Icons.check_circle,
      MissionStatus.partial => Icons.adjust,
      MissionStatus.no => Icons.cancel,
    };

    final color = switch (status) {
      MissionStatus.yes => Colors.green,
      MissionStatus.partial => Colors.orange,
      MissionStatus.no => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(status.label),
        trailing: selected ? Icon(Icons.check, color: color) : null,
        onTap: onTap,
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final SkipReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(reason.label),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: onTap,
      ),
    );
  }
}
