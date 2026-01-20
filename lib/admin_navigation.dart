import 'package:flutter/material.dart';

import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_users_page.dart';
import 'screens/admin/admin_listings_page.dart';
import 'screens/admin/admin_reports_page.dart';
import 'screens/admin/admin_settings_page.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int index = 0;

  final pages = const [
    AdminDashboardPage(),
    AdminUsersPage(),
    AdminListingsPage(),
    AdminReportsPage(),
    AdminSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
