import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ChatRoom extends StatefulWidget {
  final String chatId;
  final String otherUid;
  final String otherName;

  const ChatRoom({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _sending = false;
  bool _initialized = false;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  CollectionReference<Map<String, dynamic>> get _msgRef =>
      _chatRef.collection('messages');

  @override
  void initState() {
    super.initState();
    _initChat().then((_) async {
      await _markChatAsRead();
      await _markDelivered();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ===============================
  // INIT CHAT (WITH deletedFor)
  // ===============================
  Future<void> _initChat() async {
    if (_initialized) return;

    final me = AuthService.currentUser;
    if (me == null) return;

    final myName = await _getMyName();
    final participants = [me.uid, widget.otherUid]..sort();

    await _chatRef.set(
      {
        'participants': participants,
        'participantNames': {
          me.uid: myName,
          widget.otherUid: widget.otherName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          me.uid: 0,
          widget.otherUid: 0,
        },
        'deletedFor': {
          me.uid: false,
          widget.otherUid: false,
        },
      },
      SetOptions(merge: true),
    );

    _initialized = true;
  }

  Future<String> _getMyName() async {
    final me = AuthService.currentUser;
    if (me == null) return 'User';

    if ((me.displayName ?? '').trim().isNotEmpty) {
      return me.displayName!.trim();
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .get();

    return (snap.data()?['displayName'] ?? me.uid).toString();
  }

  // ===============================
  // UNREAD / STATUS
  // ===============================
  Future<void> _markChatAsRead() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    await _chatRef.update({'unreadCount.${me.uid}': 0});
  }

  Future<void> _markDelivered() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final snap = await _msgRef.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      final data = doc.data();
      final senderId = data['senderId'];
      final status = (data['status'] ?? 'sent').toString();

      if (senderId != me.uid && status == 'sent') {
        batch.update(doc.reference, {'status': 'delivered'});
      }
    }

    await batch.commit();
  }


  Future<void> _markSeen() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final snap = await _msgRef.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      final data = doc.data();
      final senderId = data['senderId'];
      final status = (data['status'] ?? 'sent').toString();

      if (senderId != me.uid &&
          (status == 'sent' || status == 'delivered')) {
        batch.update(doc.reference, {'status': 'seen'});
      }
    }

    await batch.commit();
  }

  // ===============================
  // SEND MESSAGE
  // ===============================
  Future<void> _sendMessage() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      final now = FieldValue.serverTimestamp();
      final myName = await _getMyName();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.set(
          _chatRef,
          {
            'lastMessage': text,
            'lastMessageAt': now,
            'lastSenderId': me.uid,
            'unreadCount.${widget.otherUid}': FieldValue.increment(1),
            'unreadCount.${me.uid}': 0,
          },
          SetOptions(merge: true),
        );

        tx.set(
          _msgRef.doc(),
          {
            'type': 'text',
            'senderId': me.uid,
            'senderName': myName,
            'text': text,
            'createdAt': now,
            'status': 'sent',
          },
        );
      });

      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _statusIcon(String? status) {
    switch (status) {
      case 'seen':
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      case 'delivered':
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      default:
        return const Icon(Icons.done, size: 16, color: Colors.grey);
    }
  }

  // ===============================
  // REPORT USER
  // ===============================
  Future<void> _reportUser() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    String reason = 'Harassment / Abuse';
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: reason,
              items: const [
                DropdownMenuItem(value: 'Harassment / Abuse', child: Text('Harassment / Abuse')),
                DropdownMenuItem(value: 'Spam / Scam', child: Text('Spam / Scam')),
                DropdownMenuItem(value: 'Inappropriate Content', child: Text('Inappropriate Content')),
                DropdownMenuItem(value: 'Fake Account', child: Text('Fake Account')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => reason = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reports').add({
                'reporterId': me.uid,
                'reportedUserId': widget.otherUid,
                'chatId': widget.chatId,
                'reason': reason,
                'description': descCtrl.text.trim(),
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ===============================
  // DELETE CHAT (SOFT DELETE)
  // ===============================
  Future<void> _deleteChat() async {
    final me = AuthService.currentUser;
    if (me == null) return;

    await _chatRef.update({
      'deletedFor.${me.uid}': true,
    });

    if (mounted) Navigator.pop(context);
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') _reportUser();
              if (v == 'delete') _deleteChat();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report User')),
              PopupMenuItem(value: 'delete', child: Text('Delete Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgRef.orderBy('createdAt').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final d = snap.data!.docs[index].data();
                    final isMe = me != null && d['senderId'] == me.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              d['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              _statusIcon(d['status']),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
