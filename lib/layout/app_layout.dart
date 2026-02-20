// layout/app_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart' show authStateProvider, authServiceProvider;

class AppLayout extends ConsumerWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the StreamProvider
    final authState = ref.watch(authStateProvider);

    // Check if user exists in the data
    final bool isLoggedIn = authState.value != null;
    final bool isLoading = authState.isLoading;

    return Scaffold(
      body: Column(
        children: [
          _Header(isLoggedIn: isLoggedIn, isLoading: isLoading),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool isLoggedIn;
  final bool isLoading;
  const _Header({required this.isLoggedIn, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          const Text(
            'MyApp',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const Spacer(),
          _NavItem('Home', () => context.go('/')),
          _NavItem('About', () => context.go('/about')),
          if (isLoggedIn) ...[
            _NavItem('Dashboard', () => context.go('/dashboard')),
            _NavItem('My Meetings', () => context.go('/meetings')),
            _NavItem('Expenses', () => context.go('/expenses')),
            _NavItem('Logout', () => authService.logout()),
          ],
          const SizedBox(width: 16),
          if (!isLoggedIn && !isLoading)
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login / Signup'),
            ),

          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavItem(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
