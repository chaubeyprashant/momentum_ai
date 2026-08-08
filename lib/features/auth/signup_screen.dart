import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/route_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_providers.dart';
import '../../services/firebase/firebase_service.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_sign_in_button.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final firebaseReady = FirebaseService.instance.isInitialized;

    Future<void> signUp() async {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;
      final confirm = confirmController.text;

      if (email.isEmpty || password.isEmpty) {
        context.showSnackBar('Please fill in all required fields.', isError: true);
        return;
      }

      if (password.length < 6) {
        context.showSnackBar('Password must be at least 6 characters.', isError: true);
        return;
      }

      if (password != confirm) {
        context.showSnackBar('Passwords do not match.', isError: true);
        return;
      }

      await ref.read(authControllerProvider.notifier).signUp(
            email: email,
            password: password,
            displayName: name.isEmpty ? null : name,
          );

      if (!context.mounted) return;

      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        final message = error is AuthException
            ? error.message
            : 'Sign up failed. Please try again.';
        context.showSnackBar(message, isError: true);
        return;
      }

      context.go(RoutePaths.onboarding);
    }

    return AuthScaffold(
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Create account',
            subtitle: 'Start building habits with your AI coach',
          ),
          if (!firebaseReady) ...[
            Card(
              color: Colors.orange.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Firebase is not configured yet. Run `flutterfire configure` '
                  'before creating an account.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AuthTextField(
            controller: nameController,
            label: 'Display name (optional)',
            hint: 'Your name',
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            controller: passwordController,
            label: 'Password',
            obscureText: obscurePassword.value,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () => obscurePassword.value = !obscurePassword.value,
            ),
          ),
          AuthTextField(
            controller: confirmController,
            label: 'Confirm password',
            obscureText: obscureConfirm.value,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => signUp(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm.value ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () => obscureConfirm.value = !obscureConfirm.value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthPrimaryButton(
            label: 'Create Account',
            isLoading: isLoading,
            onPressed: firebaseReady ? signUp : null,
          ),
          const AuthDivider(),
          const GoogleSignInButton(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?', style: TextStyle(color: Colors.white60)),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
