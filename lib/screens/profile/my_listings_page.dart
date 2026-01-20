import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    // SAFETY: auth must be ready
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your listings.')),
      );
    }

    // FIXED QUERY (MATCHES FIRESTORE RULES)
    final query = FirebaseFirestore.instance
        .collection('products') 
        .where('ownerId', isEqualTo: user.uid) 
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load listings.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('You have no listings yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final title = (data['title'] ?? '').toString();
              final category = (data['category'] ?? '').toString();
              final isActive = data['isActive'] == true;

              final price = data['price'];
              final priceText = price is num
                  ? price.toStringAsFixed(2)
                  : price?.toString() ?? '-';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(title.isEmpty ? '(Untitled)' : title),
                  subtitle: Text(
                    [
                      if (category.isNotEmpty) category,
                      'RM $priceText',
                      isActive ? 'Active' : 'Inactive',
                    ].join(' • '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, doc.reference),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content:
            const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.delete();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
