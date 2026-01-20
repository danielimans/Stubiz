// lib/screens/exchange/exchange_home.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/exchange_item.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import 'exchange_detail.dart';
import 'exchange_form.dart';

class ExchangeHome extends StatefulWidget {
  const ExchangeHome({super.key});

  @override
  State<ExchangeHome> createState() => _ExchangeHomeState();
}

class _ExchangeHomeState extends State<ExchangeHome> {
  final categories = ['All', 'Books', 'Electronics', 'Stationery', 'Others'];
  String selectedCategory = 'All';

  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamPosts() {
    return FirebaseFirestore.instance
        .collection('exchange_posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Zone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExchangeForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _streamPosts(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Failed to load: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snap.data!.docs
                    .map((d) => ExchangeItem.fromDoc(d))
                    .toList();

                final q = _searchQuery.toLowerCase().trim();

                final filteredItems = items.where((item) {
                  final matchesSearch =
                      q.isEmpty || item.title.toLowerCase().contains(q);

                  final matchesCategory =
                      selectedCategory == 'All' ||
                      item.category == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredItems.isEmpty) {
                  return EmptyState(
                    icon: Icons.swap_horiz,
                    title: 'No Exchange Items',
                    message: q.isEmpty
                        ? 'Post an item to start exchanging with other students.'
                        : 'No results for "$_searchQuery".',
                    actionText: 'Add Exchange Item',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExchangeForm()),
                      );
                    },
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: _buildExchangeCard(item),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => setState(() => selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExchangeCard(ExchangeItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExchangeDetail(item: item)),
        );
      },
      onLongPress: () => _showOptions(item),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'exchange-${item.id}',
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: Image.network(
                            item.thumbnailUrl!,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade300,
                                Colors.orange.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.swap_horiz,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge(item.category),
                      const SizedBox(width: 8),
                      _badge('Wants ${item.wantedItem}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted by ${item.ownerName.isNotEmpty ? item.ownerName : item.ownerId}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final ctrl = TextEditingController(text: _searchQuery);

    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search Exchange'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Search by title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (value == null) return;

    setState(() => _searchQuery = value.trim());
  }

  void _showOptions(ExchangeItem item) {
    final myUid = AuthService.currentUser?.uid;
    final isOwner = myUid != null && myUid == item.ownerId;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('View'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExchangeDetail(item: item)),
              );
            },
          ),
          if (isOwner) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExchangeForm(item: item)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deletePost(item);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deletePost(ExchangeItem item) async {
    try {
      await FirebaseFirestore.instance
          .collection('exchange_posts')
          .doc(item.id)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exchange post deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}
