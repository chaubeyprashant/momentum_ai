import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The URL where your hosted privacy policy lives.
/// Replace this with your actual GitHub Pages / Google Sites URL once published.
const String kPrivacyPolicyUrl = 'https://chaubeyprashant.github.io/momentum_ai_privacy_policy/';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            context,
            icon: Icons.info_outline,
            title: 'What We Collect',
            body:
                'HabitCoach AI collects the following data that you voluntarily provide:\n'
                '• Your identity goal and motivation\n'
                '• Habit completion records and streaks\n'
                '• Journal entries\n'
                '• Focus session durations\n\n'
                'This data is stored locally on your device using Hive and is never '
                'transmitted to our servers without your consent.',
          ),
          _buildSection(
            context,
            icon: Icons.psychology_outlined,
            title: 'AI Coaching Data',
            body:
                'When you use the AI Coach or Chat features, your goal description and '
                'usage context are sent to an AI provider to generate personalized '
                'coaching responses. No personally identifiable information (name, email, '
                'phone number) is required or collected.',
          ),
          _buildSection(
            context,
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            body:
                'We use Firebase Analytics to understand aggregate usage patterns '
                '(e.g., which features are most used). This data is anonymized and '
                'cannot be used to identify you personally.',
          ),
          _buildSection(
            context,
            icon: Icons.share_outlined,
            title: 'Data Sharing',
            body:
                'We do not sell, trade, or rent your personal data to third parties. '
                'Data may be shared with:\n'
                '• AI providers (only goal/context text, anonymized)\n'
                '• Firebase (Google) for crash reporting and analytics',
          ),
          _buildSection(
            context,
            icon: Icons.lock_outline,
            title: 'Data Security',
            body:
                'All local data is stored securely on your device. We implement '
                'industry-standard security practices to protect data in transit.',
          ),
          _buildSection(
            context,
            icon: Icons.delete_outline,
            title: 'Your Rights',
            body:
                'You can delete all your data at any time from '
                'Settings → Data & Privacy → Delete Account. '
                'This permanently removes all locally stored information.',
          ),
          _buildSection(
            context,
            icon: Icons.child_care_outlined,
            title: "Children's Privacy",
            body:
                'HabitCoach AI is not intended for children under 13. We do not '
                'knowingly collect data from children under 13.',
          ),
          _buildSection(
            context,
            icon: Icons.update_outlined,
            title: 'Policy Updates',
            body:
                'We may update this Privacy Policy periodically. Significant changes '
                'will be notified within the app. Continued use of the app after '
                'changes constitutes acceptance of the updated policy.',
          ),
          _buildSection(
            context,
            icon: Icons.mail_outline,
            title: 'Contact Us',
            body:
                'If you have any questions about this Privacy Policy, please contact '
                'us at:\n\nhabitcoach.ai.support@gmail.com',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Last updated: July 2025',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          OutlinedButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('View full policy online'),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined,
              size: 36, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'HabitCoach AI Privacy Policy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We respect your privacy. Here is how we handle your data.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
