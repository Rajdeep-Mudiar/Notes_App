import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/features/auth/models/user_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Token Management
  Future<bool> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(AppConstants.keyAccessToken, accessToken);
    await _prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    return true;
  }

  String? getAccessToken() {
    return _prefs.getString(AppConstants.keyAccessToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(AppConstants.keyRefreshToken);
  }

  // User Management
  Future<bool> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    return await _prefs.setString(AppConstants.keyUserData, userJson);
  }

  UserModel? getUser() {
    final userString = _prefs.getString(AppConstants.keyUserData);
    if (userString == null || userString.isEmpty) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(userString);
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // Clear Session
  Future<void> clearAuth() async {
    await _prefs.remove(AppConstants.keyAccessToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUserData);
  }

  bool hasAuth() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Theme Management
  Future<bool> saveThemeMode(String mode) async {
    return await _prefs.setString(AppConstants.keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  Future<bool> saveThemeColor(int colorValue) async {
    return await _prefs.setInt('custom_theme_primary_color', colorValue);
  }

  int? getThemeColor() {
    return _prefs.getInt('custom_theme_primary_color');
  }

  // Server URL Management
  Future<bool> saveServerUrl(String url) async {
    return await _prefs.setString('custom_server_url', url);
  }

  String? getServerUrl() {
    return _prefs.getString('custom_server_url');
  }
}
