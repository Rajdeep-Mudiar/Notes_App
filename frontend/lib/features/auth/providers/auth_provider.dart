import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exceptions.dart';
import 'package:frontend/core/storage/storage_service.dart';
import 'package:frontend/features/auth/models/auth_state.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/auth/repositories/auth_repository.dart';

// Storage Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in ProviderScope');
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage: storage);
});

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;

  AuthNotifier(this._repository, this._storage) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final hasToken = _storage.hasAuth();
    final cachedUser = _storage.getUser();

    if (!hasToken) {
      state = AuthState.unauthenticated();
      return;
    }

    if (cachedUser != null) {
      state = AuthState.authenticated(cachedUser);
    } else {
      state = AuthState.loading();
    }

    try {
      final freshUser = await _repository.getCurrentUser();
      state = AuthState.authenticated(freshUser);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storage.clearAuth();
        state = AuthState.unauthenticated();
      } else if (cachedUser != null) {
        // Keep offline cached user if server is temporarily unreachable
        state = AuthState.authenticated(cachedUser);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
      } else {
        state = AuthState.unauthenticated();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(result.user);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Failed to log in. Please try again.');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required String degree,
    required int currentSemester,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        university: university,
        degree: degree,
        currentSemester: currentSemester,
      );
      state = AuthState.authenticated(result.user);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Failed to create account. Please try again.');
      return false;
    }
  }

  Future<bool> signInWithGoogle({
    String? idToken,
    String? serverAuthCode,
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _repository.googleLogin(
        idToken: idToken,
        serverAuthCode: serverAuthCode,
        email: email,
        name: name,
        avatarUrl: avatarUrl,
      );
      state = AuthState.authenticated(result.user);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Google Sign-In failed: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? university,
    String? degree,
    int? currentSemester,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final updatedUser = await _repository.updateProfile(
        fullName: fullName,
        university: university,
        degree: degree,
        currentSemester: currentSemester,
        avatarUrl: avatarUrl,
      );
      state = AuthState.authenticated(updatedUser);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Failed to update profile. Please try again.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Auth State Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(repository, storage);
});

// Current User Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

// Backend Health Status Provider (for live dashboard indicator)
final backendHealthProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.checkHealth();
});
