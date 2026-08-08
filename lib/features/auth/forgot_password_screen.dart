import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_providers.dart';
import '../../services/firebase/firebase_service.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final emailSent = useState(false);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final firebaseReady = FirebaseService.instance.isInitialized;

    Future<void> sendReset() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        context.showSnackBar('Please enter your email address.', isError: true);
        return;
      }

      await ref.read(authControllerProvider.notifier).sendPasswordReset(email);

      if (!context.mounted) return;

      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        final message = error is AuthException
            ? error.message
            : 'Could not send reset email. Please try again.';
        context.showSnackBar(message, isError: true);
        return;
      }

      emailSent.value = true;
      context.showSnackBar('Password reset email sent. Check your inbox.');
    }

    return AuthScaffold(
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Reset password',
            subtitle: 'We\'ll email you a link to reset your password',
          ),
          if (!firebaseReady) ...[
            Card(
              color: Colors.orange.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Firebase is not configured yet. Run `flutterfire configure` first.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (emailSent.value)
            Card(
              color: Colors.green.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'If an account exists for this email, you will receive a reset link shortly.',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ),
          AuthTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => sendReset(),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthPrimaryButton(
            label: 'Send Reset Link',
            isLoading: isLoading,
            onPressed: firebaseReady && !emailSent.value ? sendReset : null,
          ),
        ],
      ),
    );
  }
}
