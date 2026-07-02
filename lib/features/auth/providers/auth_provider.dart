import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../data/mock_auth_repository.dart';

/// Estado de autenticación
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

/// Notifier de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final MockAuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.login(email, password);

    if (result.isSuccess) {
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.errorMessage,
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider global de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider para verificar si el usuario es admin
final isAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.user?.isAdmin ?? false;
});
