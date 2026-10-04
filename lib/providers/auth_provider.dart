import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/session_events.dart';
import '../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/auth.dart';
import '../models/location.dart';
import '../models/user.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  const AuthState._(this.status, this.user);

  const AuthState.loading() : this._(AuthStatus.loading, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AppUser user)
    : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final events = ref.watch(sessionEventsProvider);
    events.onSessionExpired = () {
      state = const AuthState.unauthenticated();
    };
    ref.onDispose(() => events.onSessionExpired = null);

    _bootstrap();
    return const AuthState.loading();
  }

  Future<void> _bootstrap() async {
    try {
      final tokens = await ref.read(tokenStorageProvider).read();
      if (tokens == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      final user = await ref.read(userRepositoryProvider).getMe();
      state = AuthState.authenticated(user);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear().catchError((_) {});
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> requestOtp(String phoneNumber) {
    return ref.read(authRepositoryProvider).requestOtp(phoneNumber);
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(phoneNumber: phoneNumber, code: code);
    if (result.status == VerifyOtpStatus.login && result.tokens != null) {
      await _persistTokensAndLoadUser(result.tokens!);
    }
    return result;
  }

  Future<void> completeSignup({
    required String signupToken,
    required String name,
    required String shopName,
    required LocationInput shopLocation,
    String? email,
  }) async {
    final tokens = await ref
        .read(authRepositoryProvider)
        .completeSignup(
          signupToken: signupToken,
          name: name,
          shopName: shopName,
          shopLocation: shopLocation,
          email: email,
        );
    await _persistTokensAndLoadUser(tokens);
  }

  Future<void> refreshMe() async {
    try {
      final user = await ref.read(userRepositoryProvider).getMe();
      state = AuthState.authenticated(user);
    } catch (_) {
      // Keep the current state; a transient failure shouldn't sign anyone out.
    }
  }

  Future<void> logout() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    try {
      await ref.read(authRepositoryProvider).logout(tokens?.refreshToken);
    } catch (_) {
      // Best-effort server-side revoke; still clear the local session below.
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState.unauthenticated();
  }

  Future<void> _persistTokensAndLoadUser(AuthTokens tokens) async {
    await ref
        .read(tokenStorageProvider)
        .save(
          StoredTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          ),
        );
    final user = await ref.read(userRepositoryProvider).getMe();
    state = AuthState.authenticated(user);
  }
}
