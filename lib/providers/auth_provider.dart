import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Raw Firebase auth state (signed in / signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The current user's app profile (role, store, etc.), kept live so a role
/// change by an Admin takes effect immediately without a re-login.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final auth = ref.watch(authServiceProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return auth.profileStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(null),
  );
});
