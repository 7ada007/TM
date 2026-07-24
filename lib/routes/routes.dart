import '../core/services.dart';
import '../features/admin/admin.dart';
import '../features/admin/monitoring.dart';
import '../features/auth/auth.dart';
import '../features/home/home.dart';
import '../features/lectures/lectures.dart';
import '../features/profile/profile.dart';
import '../features/splash/splash.dart';
import '../features/teacher/teacher.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static const _publicRoutes = {'/splash', '/login'};
  static const _adminRoutePrefixes = ['/admin-home', '/admin/'];
  static const _staffRoutes = {'/admin/attendance', '/admin/monitoring'};

  static String? _redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthService>();
    final path = state.matchedLocation;

    if (path == '/splash') return null;

    if (!auth.isLoggedIn) {
      return _publicRoutes.contains(path) ? null : '/login';
    }

    if (path == '/login') {
      return auth.getHomeRoute();
    }

    final isStaff = auth.isAdmin || auth.isTeacher;

    if (_staffRoutes.contains(path)) {
      return isStaff ? null : auth.getHomeRoute();
    }

    final isAdminRoute = _adminRoutePrefixes.any((p) => path.startsWith(p));
    if (isAdminRoute && !auth.isAdmin) {
      return auth.getHomeRoute();
    }

    if (path == '/teacher-home' && !isStaff) {
      return auth.getHomeRoute();
    }

    return null;
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => PremiumPageTransitions.fadeScale(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => PremiumPageTransitions.fadeSlideUp(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => PremiumPageTransitions.fadeSlideUp(
          key: state.pageKey,
          child: const HomeScreen(),
          begin: const Offset(0, 0.04),
        ),
      ),
      GoRoute(
        path: '/admin-home',
        name: 'admin-home',
        pageBuilder: (context, state) => PremiumPageTransitions.fadeSlideUp(
          key: state.pageKey,
          child: const AdminHomeScreen(),
          begin: const Offset(0, 0.04),
        ),
      ),
      GoRoute(
        path: '/admin/control-panel',
        name: 'admin-control-panel',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const AdminControlPanelScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/add-student',
        name: 'admin-add-student',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const AdminAddStudentScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/add-teacher',
        name: 'admin-add-teacher',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const AdminAddTeacherScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/monitoring',
        name: 'admin-monitoring',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const MonitoringScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/attendance',
        name: 'admin-attendance',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const AttendanceScreen(),
            ),
      ),
      GoRoute(
        path: '/teacher-home',
        name: 'teacher-home',
        pageBuilder: (context, state) => PremiumPageTransitions.fadeSlideUp(
          key: state.pageKey,
          child: const TeacherHomeScreen(),
          begin: const Offset(0, 0.04),
        ),
      ),
      GoRoute(
        path: '/lecture/:id',
        name: 'lecture-detail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return PremiumPageTransitions.sharedAxisHorizontal(
            key: state.pageKey,
            child: LectureDetailScreen(lectureId: id),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => PremiumPageTransitions.profileReveal(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/user/:id',
        name: 'user-profile',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return PremiumPageTransitions.sharedAxisHorizontal(
            key: state.pageKey,
            child: UserProfileScreen(userId: id),
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.editProfileSlide(
              key: state.pageKey,
              child: const EditProfileScreen(),
            ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        pageBuilder: (context, state) =>
            PremiumPageTransitions.sharedAxisHorizontal(
              key: state.pageKey,
              child: const HelpScreen(),
            ),
      ),
    ],
  );
}
