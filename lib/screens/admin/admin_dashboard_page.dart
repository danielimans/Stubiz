import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'admin_activity_page.dart';
import 'admin_profile_page.dart';
import 'admin_reports_page.dart';
import 'report_detail_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<int> _countUsers() async {
    final snap = await _db.collection('users').count().get();
    return snap.count ?? 0;
  }

  Future<int> _countActiveListings() async {
    final snap = await _db
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> _countPendingReports() async {
    final snap = await _db
        .collection('reports')
        .where('status', isEqualTo: 'Pending')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> _countExchangeRequests() async {
    final snap = await _db
        .collection('exchanges')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentActivities() {
    return _db
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
  }

  String _timeAgoFromTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'Under Review':
        return Colors.orange;
      case 'Pending':
      default:
        return Colors.grey;
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsFutures = Future.wait<int>([
      _countUsers(),
      _countActiveListings(),
      _countPendingReports(),
      _countExchangeRequests(),
    ]);

    return Scaffold(
      drawer: _AdminDrawer(onLogout: () => _logout(context)),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfilePage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<List<int>>(
            future: statsFutures,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _StatsLoadingGrid();
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error loading stats: ${snap.error}'),
                  ),
                );
              }

              final v = snap.data ?? [0, 0, 0, 0];
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.9,
                ),
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: '${v[0]}',
                    icon: Icons.person_outline,
                  ),
                  _StatCard(
                    title: 'Active Listings',
                    value: '${v[1]}',
                    icon: Icons.sell_outlined,
                  ),
                  _StatCard(
                    title: 'Pending Reports',
                    value: '${v[2]}',
                    icon: Icons.report_outlined,
                  ),
                  _StatCard(
                    title: 'Exchange Requests',
                    value: '${v[3]}',
                    icon: Icons.swap_horiz_outlined,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          _SectionHeader(
            title: 'Recent User Activity',
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminActivityPage()),
              );
            },
          ),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _recentActivities(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: ${snap.error}'),
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline),
                        SizedBox(width: 10),
                        Expanded(child: Text('No recent activity yet.')),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Column(
                  children: [
                    for (int i = 0; i < docs.length; i++) ...[
                      _ActivityRow(
                        username: (docs[i].data()['username'] ?? '').toString(),
                        action: (docs[i].data()['action'] ?? '').toString(),
                        time: _timeAgoFromTimestamp(
                          docs[i].data()['createdAt'] as Timestamp?,
                        ),
                      ),
                      if (i != docs.length - 1) const Divider(height: 1),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminActivityPage(),
                            ),
                          );
                        },
                        child: const Text('View All Activity'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _SectionHeader(
            title: 'Reports & Complaints',
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsPage()),
              );
            },
          ),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _recentReports(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: ${snap.error}'),
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline),
                        SizedBox(width: 10),
                        Expanded(child: Text('No reports found yet.')),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Column(
                  children: [
                    for (int i = 0; i < docs.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final data = docs[i].data();
                          final status = (data['status'] ?? 'Pending')
                              .toString();
                          final color = _statusColor(status);

                          return ListTile(
                            dense: true,
                            leading: Text(
                              (data['reportId'] ?? 'R???').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            title: Text((data['title'] ?? '').toString()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReportDetailPage(
                                          reportDocId: docs[i].id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('[View]'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (i != docs.length - 1) const Divider(height: 1),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminReportsPage(),
                            ),
                          );
                        },
                        child: const Text('View All Reports'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const _AdminDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Admin Menu'),
              subtitle: Text('StuBiz Admin'),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Activity'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminActivityPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                );
              },
            ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onViewAll),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String username;
  final String action;
  final String time;

  const _ActivityRow({
    required this.username,
    required this.action,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(
        username,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(action),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
    );
  }
}

class _StatsLoadingGrid extends StatelessWidget {
  const _StatsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    Widget box() => const Card(child: SizedBox(height: 80));
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      children: [box(), box(), box(), box()],
    );
  }
}
