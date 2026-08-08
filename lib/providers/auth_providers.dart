import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/auth_service.dart';
import '../services/firebase/firebase_service.dart';
import '../services/firebase/user_sync_service.dart';
import '../services/storage/hive_service.dart';
import 'app_providers.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  if (!FirebaseService.instance.isInitialized) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).authStateChanges;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
    ref.watch(userSyncServiceProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._sync) : super(const AsyncValue.data(null));

  final AuthService _auth;
  final UserSyncService _sync;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmail(email: email, password: password);
      await _sync.pullFromCloud();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithGoogle();
      await _sync.pullFromCloud();
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.sendPasswordResetEmail(email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
      await HiveService.instance.clearAll();
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _sync.deleteCloudData();
      await _auth.deleteAccount();
      await HiveService.instance.clearAll();
    });
  }
}

/// Syncs cloud data when auth state changes.
final cloudSyncProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) return;

  Future.microtask(() async {
    final sync = ref.read(userSyncServiceProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;

    if (profile == null || profile.id != user.uid) {
      await HiveService.instance.clearAll();
      await sync.pullFromCloud();
      ref.invalidate(userProfileProvider);
      ref.invalidate(roadmapProvider);
      ref.invalidate(timetableProvider);
      ref.invalidate(screenTimeProvider);
      ref.invalidate(habitsProvider);
    }
  });
});
