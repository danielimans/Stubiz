import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminListingsPage extends StatelessWidget {
  const AdminListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Listings')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('listings')
            .orderBy('createdAt', descending: true)
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
            return const Center(child: Text('No listings found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              final title = (d['title'] ?? 'Untitled').toString();
              final status = (d['status'] ?? 'active').toString();
              final price = (d['price'] ?? '').toString();

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  'Status: $status${price.isEmpty ? '' : ' • RM $price'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    await db.collection('listings').doc(doc.id).set({
                      'status': v,
                    }, SetOptions(merge: true));

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Listing updated to: $v')),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'active', child: Text('Set Active')),
                    PopupMenuItem(value: 'blocked', child: Text('Set Blocked')),
                    PopupMenuItem(value: 'pending', child: Text('Set Pending')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
