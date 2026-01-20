import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'report_detail_page.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('All Reports')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              final reportId = (d['reportId'] ?? 'R???').toString();
              final title = (d['title'] ?? '').toString();
              final status = (d['status'] ?? 'Pending').toString();
              final c = _statusColor(status);

              return ListTile(
                leading: Text(
                  reportId,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                title: Text(title),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailPage(reportDocId: doc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
