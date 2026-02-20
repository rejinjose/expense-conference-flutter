import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart' show authStateProvider, userRoleProvider;

import 'pages/home.dart';
import 'pages/about.dart';
import 'pages/login.dart';
import 'pages/expenses.dart';
import 'pages/permission.dart';
import 'pages/rooms/meetings.dart';
import 'pages/rooms/active_room.dart';
import 'pages/rooms/meeting_details.dart';
import 'layout/app_layout.dart';
import 'dashboard_switcher.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 1. Watch the stream of the user
  final authState = ref.watch(authStateProvider);

  final router =  GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 2. IMPORTANT: If Firebase is still "waking up", 
      // do not redirect anywhere yet. 
      final currentAuth = ref.read(authStateProvider);
      final roleAsync = ref.read(userRoleProvider);
      if (currentAuth.isLoading || roleAsync.isLoading) return null;

      // 3. Get the user (null if not logged in)
      final user = currentAuth.value;
      final isLoggedIn = user != null;
      
      final isPublicRoute = state.matchedLocation == '/' || 
                            state.matchedLocation == '/about' || 
                            state.matchedLocation == '/login';

      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // Protect Admin-specific paths
      if (isLoggedIn && state.matchedLocation.startsWith('/admin')) {
        if (roleAsync.hasValue && roleAsync.value != 'admin') return '/dashboard'; // Kick them back to user dashboard
      }

      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // 4. Handle the "Splash Screen" state here
          return authState.when(
            data: (user) => AppLayout(child: child),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              body: Center(child: Text('Auth Error: $e')),
            ),
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardSwitcher()),
          GoRoute(path: '/expenses', builder: (context, state) => const ExpensesPage()),
          GoRoute(path: '/meetings', builder: (context, state) => const MeetingsPage()),
          GoRoute(
            path: '/meeting/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return MeetingDetailsPage(roomId: roomId);
            }
          ),
          GoRoute(path: '/permission/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return PermissionPage(roomId: roomId);
            }
          ),
          GoRoute(
            path: '/room/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              final token = state.extra as String; // Retrieve the token passed from PermissionPage
              return ActiveRoomPage(roomId: roomId, token: token);
            },
          ),
        ],
      ),
    ],
  );

  // Whenever authStateProvider changes, trigger a router refresh.
  ref.listen(authStateProvider, (_, __) => router.refresh());

  // Refresh when the role changes
  // This ensures that if the 'userRoleProvider' updates (e.g., from Firestore),
  // GoRouter re-runs the redirect logic immediately.
  ref.listen(userRoleProvider, (previous, next) {
    if (previous?.value != next.value || previous?.isLoading != next.isLoading) {
      router.refresh();
    }
  });

  return router;
});


