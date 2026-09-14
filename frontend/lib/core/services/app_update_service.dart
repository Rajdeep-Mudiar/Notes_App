import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
  });

  factory AppUpdateInfo.none({required String currentVersion}) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      downloadUrl: '',
      releaseNotes: '',
    );
  }
}

class AppUpdateService {
  static const String currentAppVersion = '1.0.0';
  static const String githubRepo = 'Rajdeep-Mudiar/Notes_App';
  static const String fallbackReleasesUrl = 'https://github.com/$githubRepo/releases/latest';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'User-Agent': 'StudentOS-Flutter'},
    ),
  );

  /// Check GitHub Releases API directly or through backend
  Future<AppUpdateInfo> checkForUpdates({String? backendBaseUrl}) async {
    // 1. Try checking GitHub Releases API directly
    try {
      final githubUrl = 'https://api.github.com/repos/$githubRepo/releases/latest';
      final response = await _dio.get(githubUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data as String) : response.data;
        final rawTag = (data['tag_name'] ?? '').toString().replaceAll('v', '').trim();
        final releaseNotes = (data['body'] ?? 'New release available with performance improvements and bug fixes.').toString();
        final htmlUrl = (data['html_url'] ?? fallbackReleasesUrl).toString();

        String downloadUrl = htmlUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetName = (asset['name'] ?? '').toString();
          if (assetName.endsWith('.apk')) {
            downloadUrl = (asset['browser_download_url'] ?? htmlUrl).toString();
            break;
          }
        }

        if (rawTag.isNotEmpty) {
          final hasUpdate = _isVersionNewer(currentAppVersion, rawTag);
          return AppUpdateInfo(
            hasUpdate: hasUpdate,
            currentVersion: currentAppVersion,
            latestVersion: rawTag,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
          );
        }
      }
    } catch (e) {
      debugPrint('GitHub Release check failed: $e');
    }

    // 2. Fallback: Check backend endpoint if URL provided
    if (backendBaseUrl != null) {
      try {
        final endpoint = '$backendBaseUrl/api/v1/system/check-update?client_version=$currentAppVersion';
        final response = await _dio.get(endpoint);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'];
          if (data != null) {
            return AppUpdateInfo(
              hasUpdate: data['update_available'] ?? false,
              currentVersion: currentAppVersion,
              latestVersion: (data['latest_version'] ?? currentAppVersion).toString(),
              downloadUrl: (data['download_url'] ?? fallbackReleasesUrl).toString(),
              releaseNotes: (data['release_notes'] ?? '').toString(),
              isMandatory: data['is_mandatory'] ?? false,
            );
          }
        }
      } catch (e) {
        debugPrint('Backend version check failed: $e');
      }
    }

    return AppUpdateInfo.none(currentVersion: currentAppVersion);
  }

  /// Compare semantic versions (e.g., '1.0.1' > '1.0.0')
  bool _isVersionNewer(String current, String latest) {
    try {
      final curParts = current.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latParts = latest.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (curParts.length < 3) {
        curParts.add(0);
      }
      while (latParts.length < 3) {
        latParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latParts[i] > curParts[i]) return true;
        if (latParts[i] < curParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Launch download URL in device browser
  Future<bool> launchDownload(String url) async {
    final uri = Uri.parse(url.isNotEmpty ? url : fallbackReleasesUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
    return false;
  }
}
