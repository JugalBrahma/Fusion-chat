import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for current user stream
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider for authentication state
final authStateProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.value != null;
});
