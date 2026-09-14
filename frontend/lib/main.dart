import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/storage/storage_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage
  final storageService = await StorageService.init();

  // Initialize custom server URL if previously configured
  final savedServerUrl = storageService.getServerUrl();
  if (savedServerUrl != null && savedServerUrl.isNotEmpty) {
    ApiEndpoints.setCustomBaseUrl(savedServerUrl);
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const StudentOSApp(),
    ),
  );
}

class StudentOSApp extends ConsumerWidget {
  const StudentOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Notoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
