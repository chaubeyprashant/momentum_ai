import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/habit.dart';
import '../../services/storage/hive_service.dart';

class FocusScreen extends HookConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = useState(false);
    final secondsLeft = useState(AppConstants.defaultPomodoroMinutes * 60);
    final totalSeconds = useState(AppConstants.defaultPomodoroMinutes * 60);
    final sessionId = useState<String?>(null);
    final timerRef = useRef<Timer?>(null);

    useEffect(() {
      return () => timerRef.value?.cancel();
    }, []);

    void startTimer() {
      sessionId.value = const Uuid().v4();
      isRunning.value = true;
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft.value > 0) {
          secondsLeft.value--;
        } else {
          timer.cancel();
          isRunning.value = false;
          _completeSession(sessionId.value!, totalSeconds.value);
        }
      });
    }

    void pauseTimer() {
      timerRef.value?.cancel();
      isRunning.value = false;
    }

    void resetTimer() {
      timerRef.value?.cancel();
      isRunning.value = false;
      secondsLeft.value = totalSeconds.value;
    }

    final progress = 1 - (secondsLeft.value / totalSeconds.value);
    final minutes = secondsLeft.value ~/ 60;
    final seconds = secondsLeft.value % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Work Mode'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.timer_outlined),
            onSelected: (mins) {
              totalSeconds.value = mins * 60;
              secondsLeft.value = mins * 60;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 25, child: Text('25 min')),
              const PopupMenuItem(value: 45, child: Text('45 min')),
              const PopupMenuItem(value: 60, child: Text('60 min'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isRunning.value ? 'Stay focused' : 'Ready to begin',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRunning.value)
                  _FocusButton(
                    icon: Icons.pause,
                    label: 'Pause',
                    onTap: pauseTimer,
                  )
                else
                  _FocusButton(
                    icon: Icons.play_arrow,
                    label: secondsLeft.value < totalSeconds.value
                        ? 'Resume'
                        : 'Start',
                    onTap: startTimer,
                    isPrimary: true,
                  ),
                const SizedBox(width: AppSpacing.md),
                _FocusButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onTap: resetTimer,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: SwitchListTile(
                title: const Text('Block notifications'),
                subtitle: const Text('Minimize distractions'),
                value: true,
                onChanged: (_) {},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Focus sounds'),
                subtitle: const Text('Rain • White noise • Lo-fi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSession(String id, int totalSeconds) async {
    final session = FocusSession(
      id: id,
      startedAt: DateTime.now().subtract(Duration(seconds: totalSeconds)),
      endedAt: DateTime.now(),
      durationMinutes: totalSeconds ~/ 60,
      completed: true,
    );
    final hive = HiveService.instance;
    final sessions = hive.getFocusSessions()..add(session);
    await hive.saveFocusSessions(sessions);
  }
}

class _FocusButton extends StatelessWidget {
  const _FocusButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isPrimary ? AppColors.primary : null,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
