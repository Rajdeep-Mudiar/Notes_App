import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/features/auth/models/auth_state.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/screens/register_screen.dart';
import 'package:frontend/features/auth/screens/profile_screen.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/features/assignments/screens/assignments_screen.dart';
import 'package:frontend/features/exams/screens/exams_screen.dart';
import 'package:frontend/features/files/screens/files_screen.dart';
import 'package:frontend/features/notes/screens/note_editor_screen.dart';
import 'package:frontend/features/notes/screens/notes_list_screen.dart';
import 'package:frontend/features/subjects/screens/subject_detail_screen.dart';
import 'package:frontend/features/subjects/screens/subjects_screen.dart';
import 'package:frontend/features/timetable/screens/timetable_screen.dart';
import 'package:frontend/features/notifications/screens/notifications_screen.dart';
import 'package:frontend/features/ai/screens/ai_study_assistant_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final isAuth = authState.isAuthenticated;
    final isInitialOrLoading = authState.isInitial;
    final location = state.uri.path;
    final matched = state.matchedLocation;
    final isLoginRoute = location == RouteNames.login || matched == RouteNames.login;
    final isRegisterRoute = location == RouteNames.register || matched == RouteNames.register;

    // Still checking local token storage on startup
    if (isInitialOrLoading) {
      return null;
    }

    // If user is not authenticated and trying to access protected screens
    if (!isAuth && !isLoginRoute && !isRegisterRoute) {
      return RouteNames.login;
    }

    // If user is authenticated and trying to visit login/register
    if (isAuth && (isLoginRoute || isRegisterRoute)) {
      return RouteNames.home;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.subjects,
        builder: (context, state) => const SubjectsScreen(),
      ),
      GoRoute(
        path: '/subjects/:id',
        builder: (context, state) {
          final subjectId = state.pathParameters['id'] ?? '';
          return SubjectDetailScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: RouteNames.notes,
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(
        path: '/notes/new',
        builder: (context, state) {
          final subjectId = state.uri.queryParameters['subject_id'];
          return NoteEditorScreen(initialSubjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return NoteEditorScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: RouteNames.files,
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        path: RouteNames.assignments,
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: RouteNames.exams,
        builder: (context, state) => const ExamsScreen(initialTabIndex: 0),
      ),
      GoRoute(
        path: RouteNames.calendar,
        builder: (context, state) => const ExamsScreen(initialTabIndex: 1),
      ),
      GoRoute(
        path: RouteNames.timetable,
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.ai,
        builder: (context, state) => const AiStudyAssistantScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
});


