import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('users')
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
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final email = (d['email'] ?? '').toString();
              final role = (d['role'] ?? '').toString();
              final verified = (d['emailVerified'] ?? false) == true;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(email.isEmpty ? docs[i].id : email),
                subtitle: Text('Role: $role • Verified: $verified'),
              );
            },
          );
        },
      ),
    );
  }
}
