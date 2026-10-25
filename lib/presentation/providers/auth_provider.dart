import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../di/providers.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthStateNotifier(repo, secureStorage, ref);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;
  final bool requiresTotp;
  final String? tempToken;
  final bool sessionExpiring;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.requiresTotp = false,
    this.tempToken,
    this.sessionExpiring = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
    bool? requiresTotp,
    String? tempToken,
    bool? sessionExpiring,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      requiresTotp: requiresTotp ?? this.requiresTotp,
      tempToken: tempToken ?? this.tempToken,
      sessionExpiring: sessionExpiring ?? this.sessionExpiring,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final dynamic _repo;
  final dynamic _secureStorage;
  final Ref _ref;
  Timer? _heartbeatTimer;

  AuthStateNotifier(this._repo, this._secureStorage, this._ref) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await _secureStorage.getToken();
    if (token == null) return;
    try {
      _ref.read(apiClientProvider).updateToken(token);
      final user = await _repo.getProfile();
      state = state.copyWith(isAuthenticated: true, user: user);
      _startHeartbeat();
    } catch (_) {
      await _secureStorage.deleteToken();
    }
  }

  Future<void> login(String username, String password, {String? turnstileToken}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final useCase = LoginUseCase(_repo);
      final result = await useCase(username, password, turnstileToken: turnstileToken);
      if (result.requiresTotp) {
        state = state.copyWith(isLoading: false, requiresTotp: true, tempToken: result.tempToken);
      } else {
        state = state.copyWith(isAuthenticated: true, isLoading: false, user: result.user, error: null);
        _startHeartbeat();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyTotp(String code, {String? turnstileToken}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.verifyTotp(state.tempToken!, code, turnstileToken: turnstileToken);
      state = state.copyWith(isAuthenticated: true, isLoading: false, user: result.user, requiresTotp: false, tempToken: null, error: null);
      _startHeartbeat();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    _heartbeatTimer?.cancel();
    await _repo.logout();
    state = const AuthState();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (_) => _heartbeat());
  }

  Future<void> _heartbeat() async {
    try {
      final user = await _repo.getProfile();
      state = state.copyWith(user: user, sessionExpiring: false);
    } catch (_) {
      state = state.copyWith(sessionExpiring: true);
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
