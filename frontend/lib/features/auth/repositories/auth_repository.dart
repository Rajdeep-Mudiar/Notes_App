import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/models/auth_tokens.dart';
import 'package:frontend/features/auth/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<({UserModel user, AuthTokens tokens})> register({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required String degree,
    required int currentSemester,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName.trim(),
        'university': university.trim(),
        'degree': degree.trim(),
        'current_semester': currentSemester,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);

    // Save tokens and user locally
    await _apiClient.storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _apiClient.storage.saveUser(user);

    return (user: user, tokens: tokens);
  }

  Future<({UserModel user, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);

    // Save tokens and user locally
    await _apiClient.storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _apiClient.storage.saveUser(user);

    return (user: user, tokens: tokens);
  }

  Future<({UserModel user, AuthTokens tokens})> googleLogin({
    String? idToken,
    String? serverAuthCode,
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.googleAuth,
      data: {
        if (idToken != null) 'id_token': idToken,
        if (serverAuthCode != null) 'server_auth_code': serverAuthCode,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);

    // Save tokens and user locally
    await _apiClient.storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _apiClient.storage.saveUser(user);

    return (user: user, tokens: tokens);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.userMe);
    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    await _apiClient.storage.saveUser(user);
    return user;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? university,
    String? degree,
    int? currentSemester,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName.trim();
    if (university != null) payload['university'] = university.trim();
    if (degree != null) payload['degree'] = degree.trim();
    if (currentSemester != null) payload['current_semester'] = currentSemester;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

    final response = await _apiClient.put(
      ApiEndpoints.userMe,
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    await _apiClient.storage.saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _apiClient.get(ApiEndpoints.health);
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _apiClient.storage.clearAuth();
    }
  }
}
