import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportDocId;
  const ReportDetailPage({super.key, required this.reportDocId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('reports')
        .doc(reportDocId);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: docRef.get(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Report not found.'));
          }

          final data = snap.data!.data()!;
          final status = (data['status'] ?? 'Pending').toString();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['reportId'] ?? 'R???').toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (data['title'] ?? '').toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text('Status: $status'),
                const SizedBox(height: 12),
                Text('Details:\n${(data['details'] ?? '').toString()}'),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await docRef.set({
                            'status': 'Under Review',
                          }, SetOptions(merge: true));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Marked as Under Review'),
                            ),
                          );
                        },
                        child: const Text('Under Review'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await docRef.set({
                            'status': 'Resolved',
                          }, SetOptions(merge: true));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Resolved')),
                          );
                        },
                        child: const Text('Resolve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
