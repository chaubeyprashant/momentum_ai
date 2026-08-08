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

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final firebaseReady = FirebaseService.instance.isInitialized;

    Future<void> signIn() async {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        context.showSnackBar('Please enter your email and password.', isError: true);
        return;
      }

      await ref.read(authControllerProvider.notifier).signIn(
            email: email,
            password: password,
          );

      if (!context.mounted) return;

      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        final message = error is AuthException
            ? error.message
            : 'Sign in failed. Please try again.';
        context.showSnackBar(message, isError: true);
        return;
      }

      context.go(RoutePaths.splash);
    }

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Welcome back',
            subtitle: 'Sign in to continue your journey',
          ),
          if (!firebaseReady) ...[
            Card(
              color: Colors.orange.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Firebase is not configured yet. Run `flutterfire configure` '
                  'and add your platform config files before signing in.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => signIn(),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () => obscurePassword.value = !obscurePassword.value,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthPrimaryButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: firebaseReady ? signIn : null,
          ),
          const AuthDivider(),
          const GoogleSignInButton(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?", style: TextStyle(color: Colors.white60)),
              TextButton(
                onPressed: () => context.push(RoutePaths.signUp),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
