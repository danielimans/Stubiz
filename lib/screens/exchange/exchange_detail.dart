// lib/screens/exchange/exchange_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../models/exchange_item.dart';
import '../../services/auth_service.dart';
import '../chat/chat_room.dart';
import 'exchange_form.dart';

class ExchangeDetail extends StatelessWidget {
  final ExchangeItem item;
  const ExchangeDetail({super.key, required this.item});

  bool _isOwner() {
    final me = AuthService.currentUser;
    return me != null && me.uid == item.ownerId;
  }

  Future<String> _getMyName() async {
    final me = AuthService.currentUser;
    if (me == null) return 'Student';

    final authName = (me.displayName ?? '').trim();
    if (authName.isNotEmpty) return authName;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .get();
    final name = (snap.data()?['displayName'] ?? '').toString().trim();
    return name.isNotEmpty ? name : me.uid;
  }

  Future<void> _openChatWithOwner(BuildContext context) async {
    final me = AuthService.currentUser!;
    if (me.uid == item.ownerId) return;

    final otherUid = item.ownerId;
    final otherName = item.ownerName.isNotEmpty ? item.ownerName : otherUid;

    final ids = [me.uid, otherUid]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatRoom(chatId: chatId, otherUid: otherUid, otherName: otherName),
      ),
    );
  }

  // ---------- REQUEST EXCHANGE (REAL) ----------
  Future<void> _requestExchange(BuildContext context) async {
    final me = AuthService.currentUser!;
    if (me.uid == item.ownerId) return;

    // deterministic id: one user can only request same post one doc
    final exchangeId = '${item.id}_${me.uid}';
    final ref = FirebaseFirestore.instance
        .collection('exchanges')
        .doc(exchangeId);

    try {
      final myName = await _getMyName();

      // IMPORTANT: no ref.get() here (avoids permission-denied on non-existing doc)
      // Use merge:true so if user taps again, it updates instead of failing.
      await ref.set({
        'requesterId': me.uid,
        'ownerId': item.ownerId,

        'requesterName': myName,
        'ownerName': item.ownerName,
        'exchangePostId': item.id,
        'postTitle': item.title,
        'postThumbnailUrl': item.thumbnailUrl,
        'wantedItem': item.wantedItem,
        'category': item.category,

        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exchange request sent.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request failed: $e')));
    }
  }

  // ---------- OWNER: DELETE ----------
  Future<void> _deletePost(BuildContext context) async {
    final me = AuthService.currentUser;
    if (me == null) return;
    if (me.uid != item.ownerId) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this exchange post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // delete images (best-effort)
      for (final url in item.imageUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }

      await FirebaseFirestore.instance
          .collection('exchange_posts')
          .doc(item.id)
          .delete();

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _editPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExchangeForm(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroUrl = item.thumbnailUrl;
    final isOwner = _isOwner();

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'exchange-${item.id}',
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: (heroUrl != null && heroUrl.isNotEmpty)
                    ? Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Image.network(heroUrl, fit: BoxFit.contain),
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
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(item.category),
                        backgroundColor: Colors.orange.shade50,
                      ),
                      Chip(
                        label: Text('Wants: ${item.wantedItem}'),
                        backgroundColor: Colors.green.shade50,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Posted by ${item.ownerName.isNotEmpty ? item.ownerName : item.ownerId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 18),

                  if (item.imageUrls.isNotEmpty) ...[
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.imageUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final url = item.imageUrls[i];
                          return InkWell(
                            onTap: () => _openGallery(context, startIndex: i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  const Text(
                    'Item Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Looking to Exchange For',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(item.wantedItem),
                    backgroundColor: Colors.green.shade50,
                  ),

                  const SizedBox(height: 28),

                  // ---------- Actions ----------
                  if (!isOwner) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.swap_calls),
                        label: const Text('Request Exchange'),
                        onPressed: () => _requestExchange(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat with owner'),
                        onPressed: () => _openChatWithOwner(context),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () => _editPost(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            onPressed: () => _deletePost(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, {required int startIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _GalleryPage(urls: item.imageUrls, startIndex: startIndex),
      ),
    );
  }
}

class _GalleryPage extends StatefulWidget {
  final List<String> urls;
  final int startIndex;
  const _GalleryPage({required this.urls, required this.startIndex});

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  late final PageController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Photos'),
      ),
      body: PageView.builder(
        controller: ctrl,
        itemCount: widget.urls.length,
        itemBuilder: (context, i) {
          final url = widget.urls[i];
          return InteractiveViewer(
            child: Container(
              color: Colors.grey.shade900,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
          );
        },
      ),
    );
  }
}
