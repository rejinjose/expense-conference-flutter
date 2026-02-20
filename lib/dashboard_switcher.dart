// dashboard_switcher.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './providers/auth_provider.dart';
import './pages/dashboard.dart';
import './pages/admin_dashboard.dart';

class DashboardSwitcher extends ConsumerWidget {
  const DashboardSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == 'admin') {
          return const AdminDashboardPage();
        }
        return const DashboardPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading role: $err')),
      ),
    );
  }
}
