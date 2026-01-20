import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MyExchangesPage extends StatelessWidget {
  const MyExchangesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final requesterQuery = FirebaseFirestore.instance
        .collection('exchanges')
        .where('requesterId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    final ownerQuery = FirebaseFirestore.instance
        .collection('exchanges')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Exchanges')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requesterQuery.snapshots(),
        builder: (context, snapA) {
          if (snapA.hasError) {
            return Center(child: Text('Failed: ${snapA.error}'));
          }
          if (!snapA.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ownerQuery.snapshots(),
            builder: (context, snapB) {
              if (snapB.hasError) {
                return Center(child: Text('Failed: ${snapB.error}'));
              }
              if (!snapB.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final map =
                  <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
              for (final d in snapA.data!.docs) {
                map[d.id] = d;
              }
              for (final d in snapB.data!.docs) {
                map[d.id] = d;
              }
              final docs = map.values.toList();

              docs.sort((x, y) {
                final ax = x.data()['createdAt'];
                final ay = y.data()['createdAt'];
                final tx = ax is Timestamp ? ax : Timestamp(0, 0);
                final ty = ay is Timestamp ? ay : Timestamp(0, 0);
                return ty.compareTo(tx);
              });

              if (docs.isEmpty) {
                return const Center(child: Text('No exchanges yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                // FIX: (_, _) instead of (_, __)
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data();

                  final status = (data['status'] ?? 'pending').toString();
                  final requesterId = (data['requesterId'] ?? '').toString();
                  final ownerId = (data['ownerId'] ?? '').toString();

                  final requesterName = (data['requesterName'] ?? '')
                      .toString();
                  final ownerName = (data['ownerName'] ?? '').toString();

                  final iAmRequester = requesterId == user.uid;
                  final otherName = iAmRequester
                      ? (ownerName.isNotEmpty ? ownerName : ownerId)
                      : (requesterName.isNotEmpty
                            ? requesterName
                            : requesterId);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: Text('With: $otherName'),
                      subtitle: Text('Status: $status'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exchange ID: ${d.id}')),
                        );
                      },
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
