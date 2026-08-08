import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_paths.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_logger.dart';
import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/coach_message_card.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final isLoading = useState(false);

    final goalCategory = useState<GoalCategory?>(null);
    final identityGoal = useState('');
    final deadline = useState<GoalDeadline?>(null);
    final customDeadlineDays = useState<int?>(null);
    final skillLevel = useState<SkillLevel?>(null);
    final dailyHours = useState<DailyHours?>(null);
    final customDailyHours = useState<double?>(null);
    final motivation = useState('');

    final steps = [
      _StepData(
        title: 'What are you working on?',
        subtitle: 'Students, parents, professionals — everyone\'s welcome',
        child: _GoalStep(
          category: goalCategory.value,
          value: identityGoal.value,
          onCategory: (c) => goalCategory.value = c,
          onChanged: (v) => identityGoal.value = v,
        ),
      ),
      _StepData(
        title: 'When is your deadline?',
        subtitle: 'Set a realistic timeline',
        child: _DeadlineStep(
          selected: deadline.value,
          customDays: customDeadlineDays.value,
          onSelected: (d) => deadline.value = d,
          onCustomDays: (d) => customDeadlineDays.value = d,
        ),
      ),
      _StepData(
        title: 'How familiar are you?',
        subtitle: 'We\'ll match the pace to you',
        child: _SkillLevelStep(
          selected: skillLevel.value,
          onSelected: (s) => skillLevel.value = s,
        ),
      ),
      _StepData(
        title: 'Hours available daily?',
        subtitle: 'Consistency beats intensity',
        child: _DailyHoursStep(
          selected: dailyHours.value,
          customHours: customDailyHours.value,
          onSelected: (h) => dailyHours.value = h,
          onCustomHours: (h) => customDailyHours.value = h,
        ),
      ),
      _StepData(
        title: 'Why is this important?',
        subtitle: 'Your AI coach will remind you on hard days',
        child: _MotivationStep(
          value: motivation.value,
          onChanged: (v) => motivation.value = v,
        ),
      ),
    ];

    bool canProceed() {
      switch (currentPage.value) {
        case 0:
          return goalCategory.value != null &&
              identityGoal.value.trim().length >= 3;
        case 1:
          if (deadline.value == null) return false;
          if (deadline.value == GoalDeadline.custom) {
            return (customDeadlineDays.value ?? 0) > 0;
          }
          return true;
        case 2:
          return skillLevel.value != null;
        case 3:
          if (dailyHours.value == null) return false;
          if (dailyHours.value == DailyHours.custom) {
            return (customDailyHours.value ?? 0) > 0;
          }
          return true;
        case 4:
          return motivation.value.trim().length >= 10;
        default:
          return false;
      }
    }

    Future<void> completeOnboarding() async {
      isLoading.value = true;
      try {
        final userId = ref.read(authServiceProvider).currentUser?.uid;
        final profile = UserProfile(
          id: userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          identityGoal: identityGoal.value.trim(),
          goalCategory: goalCategory.value ?? GoalCategory.habits,
          deadline: deadline.value!,
          skillLevel: skillLevel.value!,
          dailyHours: dailyHours.value!,
          motivation: motivation.value.trim(),
          customDeadlineDays: customDeadlineDays.value,
          customDailyHours: customDailyHours.value,
          displayName: ref.read(authServiceProvider).currentUser?.displayName,
        );

        await ref.read(userProfileProvider.notifier).completeOnboarding(profile);
        await ref.read(roadmapProvider.notifier).generate(profile);
        try {
          await ref.read(timetableProvider.notifier).generateFromProfile(profile);
          AppLogger.info('Onboarding', 'Timetable generated during onboarding');
        } catch (e, stack) {
          AppLogger.warning(
            'Onboarding',
            'Timetable generation skipped/failed — user can add Gemini key in Settings',
            e,
            stack,
          );
        }

        if (context.mounted) {
          context.go(RoutePaths.home);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('Something went wrong. Please try again.', isError: true);
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                children: [
                  if (currentPage.value > 0)
                    IconButton(
                      onPressed: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentPage.value + 1) / steps.length,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => currentPage.value = i,
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          step.subtitle,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Expanded(child: step.child),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              child: PrimaryButton(
                label: currentPage.value == steps.length - 1
                    ? 'Generate My Roadmap'
                    : 'Continue',
                isLoading: isLoading.value,
                onPressed: canProceed()
                    ? () {
                        if (currentPage.value == steps.length - 1) {
                          completeOnboarding();
                        } else {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.category,
    required this.value,
    required this.onCategory,
    required this.onChanged,
  });

  final GoalCategory? category;
  final String value;
  final ValueChanged<GoalCategory> onCategory;
  final ValueChanged<String> onChanged;

  static const _suggestions = {
    GoalCategory.health: ['Exercise daily', 'Eat healthier', 'Sleep better', 'Drink more water'],
    GoalCategory.habits: ['Wake up early', 'Read daily', 'Meditate', 'Journal'],
    GoalCategory.learning: ['Learn a language', 'Study for exams', 'Learn coding', 'Read books'],
    GoalCategory.productivity: ['Stay organized', 'Finish projects', 'Plan my day'],
    GoalCategory.creativity: ['Draw daily', 'Write a book', 'Learn music', 'Photography'],
    GoalCategory.relationships: ['Family time', 'Call parents', 'Be more present'],
    GoalCategory.screenTime: ['Less phone use', 'No social media mornings', 'Digital detox'],
    GoalCategory.career: ['Get a new job', 'Build skills', 'Start a business'],
    GoalCategory.other: ['Build confidence', 'Be more consistent', 'Improve myself'],
  };

  @override
  Widget build(BuildContext context) {
    final suggestions = category != null ? _suggestions[category]! : <String>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: GoalCategory.values.map((c) {
              return FilterChip(
                label: Text(c.label),
                selected: category == c,
                onSelected: (_) => onCategory(c),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: category == GoalCategory.screenTime
                  ? 'e.g. Limit phone to 2 hours'
                  : 'e.g. ${suggestions.isNotEmpty ? suggestions.first : "Your goal"}',
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Ideas', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: suggestions.map((s) {
                return FilterChip(
                  label: Text(s),
                  selected: value == s,
                  onSelected: (_) => onChanged(s),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeadlineStep extends StatelessWidget {
  const _DeadlineStep({
    required this.selected,
    required this.customDays,
    required this.onSelected,
    required this.onCustomDays,
  });

  final GoalDeadline? selected;
  final int? customDays;
  final ValueChanged<GoalDeadline> onSelected;
  final ValueChanged<int> onCustomDays;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...GoalDeadline.values.map((d) => _OptionTile(
              label: d.label,
              selected: selected == d,
              onTap: () => onSelected(d),
            )),
        if (selected == GoalDeadline.custom) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Number of days',
              suffixText: 'days',
            ),
            onChanged: (v) => onCustomDays(int.tryParse(v) ?? 0),
          ),
        ],
      ],
    );
  }
}

class _SkillLevelStep extends StatelessWidget {
  const _SkillLevelStep({required this.selected, required this.onSelected});

  final SkillLevel? selected;
  final ValueChanged<SkillLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: SkillLevel.values
          .map((s) => _OptionTile(
                label: s.label,
                selected: selected == s,
                onTap: () => onSelected(s),
              ))
          .toList(),
    );
  }
}

class _DailyHoursStep extends StatelessWidget {
  const _DailyHoursStep({
    required this.selected,
    required this.customHours,
    required this.onSelected,
    required this.onCustomHours,
  });

  final DailyHours? selected;
  final double? customHours;
  final ValueChanged<DailyHours> onSelected;
  final ValueChanged<double> onCustomHours;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...DailyHours.values.map((h) => _OptionTile(
              label: h.label,
              selected: selected == h,
              onTap: () => onSelected(h),
            )),
        if (selected == DailyHours.custom) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Hours per day',
              suffixText: 'hrs',
            ),
            onChanged: (v) => onCustomHours(double.tryParse(v) ?? 0),
          ),
        ],
      ],
    );
  }
}

class _MotivationStep extends StatelessWidget {
  const _MotivationStep({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      maxLines: 6,
      decoration: const InputDecoration(
        hintText:
            'I want to transform my life because...\n\nThis will be shown to you on tough days.',
        alignLabelWithHint: true,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check_circle, color: context.colorScheme.primary)
            : const Icon(Icons.circle_outlined),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
    );
  }
}
