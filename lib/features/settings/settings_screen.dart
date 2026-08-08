import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../services/ai/gemini_config.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/storage/hive_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _aiAvailable = false;
  String _aiModel = GeminiConfig.defaultModel;
  bool _missedTaskCallsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAiStatus();
    _missedTaskCallsEnabled = HiveService.instance.getMissedTaskCallsEnabled();
  }

  Future<void> _loadAiStatus() async {
    final configured = await GeminiConfig.isConfigured;
    final model = await GeminiConfig.getModel();
    if (mounted) {
      setState(() {
        _aiAvailable = configured;
        _aiModel = model;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          if (FirebaseService.instance.isInitialized) ...[
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Signed in as'),
              subtitle: Text(
                ref.watch(authServiceProvider).currentUser?.email ?? 'Unknown',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _signOut(context, ref),
            ),
          ],
          const _SectionHeader('AI'),
          ListTile(
            leading: Icon(
              _aiAvailable ? Icons.auto_awesome : Icons.cloud_off_outlined,
              color: _aiAvailable ? Colors.green : null,
            ),
            title: const Text('AI Features'),
            subtitle: Text(
              _aiAvailable
                  ? 'Powered by Gemini · $_aiModel'
                  : 'Unavailable in this build',
            ),
          ),
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(themeMode == ThemeMode.dark ? 'On' : 'Off'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const _SectionHeader('AI Coach'),
          ListTile(
            title: const Text('AI Personality'),
            subtitle: Text(profile?.aiPersonality.label ?? 'Supportive Coach'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPersonalityPicker(context, ref, profile),
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Daily Reminders'),
            subtitle: const Text('Task reminders from your timetable'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text('Missed Task Reminder Calls'),
            subtitle: const Text(
              'Urgent call-style alerts when you miss a scheduled task',
            ),
            value: _missedTaskCallsEnabled,
            onChanged: (value) async {
              setState(() => _missedTaskCallsEnabled = value);
              await HiveService.instance.setMissedTaskCallsEnabled(value);
              if (value) {
                await ref.read(timetableProvider.notifier).load();
              }
            },
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Coach messages & streak alerts'),
            value: true,
            onChanged: (_) {},
          ),
          const _SectionHeader('Feedback'),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            subtitle: const Text('Report bugs, request features, share ideas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePaths.feedback),
          ),
          const _SectionHeader('Data & Privacy'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export Data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDelete(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePaths.privacyPolicy),
          ),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: const Text(AppConstants.appVersion, style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate HabitCoach AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon on Play Store!')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showPersonalityPicker(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AiPersonality.values.map((p) {
            return ListTile(
              title: Text(p.label),
              onTap: () async {
                if (profile != null) {
                  await ref.read(userProfileProvider.notifier).save(
                        profile.copyWith(aiPersonality: p),
                      );
                }
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).signOut();
    ref.invalidate(userProfileProvider);
    ref.invalidate(roadmapProvider);

    if (context.mounted) {
      context.go(RoutePaths.login);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete all your data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (FirebaseService.instance.isInitialized) {
          await ref.read(authControllerProvider.notifier).deleteAccount();
        } else {
          await ref.read(authControllerProvider.notifier).signOut();
        }
        ref.invalidate(userProfileProvider);
        ref.invalidate(roadmapProvider);
        if (context.mounted) {
          context.go(RoutePaths.login);
        }
      } catch (e) {
        if (context.mounted) {
          final message = e is AuthException
              ? e.message
              : 'Could not delete account. Please try again.';
          context.showSnackBar(message, isError: true);
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
