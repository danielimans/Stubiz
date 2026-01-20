// lib/screens/chat/chat_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'chat_room.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamChats(String myUid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots(); 
  }

  String _initialLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  String _safeOtherName(Map<String, dynamic> data, String otherUid) {
    final namesMap = (data['participantNames'] is Map)
        ? Map<String, dynamic>.from(data['participantNames'] as Map)
        : <String, dynamic>{};

    final otherName = (namesMap[otherUid] ?? '').toString().trim();
    return otherName.isNotEmpty ? otherName : 'Student User';
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is! Timestamp) return '';

    final date = ts.toDate().toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;

    if (me == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamChats(me.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load chats:\n${snap.error}'),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // FILTER + SORT CLIENT-SIDE 
          final docs = snap.data!.docs.where((doc) {
            final deletedFor = doc.data()['deletedFor'];
            if (deletedFor is Map && deletedFor[me.uid] == true) {
              return false;
            }
            return true;
          }).toList()
            ..sort((a, b) {
              final ta = a.data()['lastMessageAt'];
              final tb = b.data()['lastMessageAt'];
              final da = ta is Timestamp ? ta : Timestamp(0, 0);
              final db = tb is Timestamp ? tb : Timestamp(0, 0);
              return db.compareTo(da); // newest first
            });

          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final participants = (data['participants'] is List)
                  ? (data['participants'] as List)
                      .map((e) => e.toString())
                      .toList()
                  : <String>[];

              final otherUid = participants.firstWhere(
                (id) => id != me.uid,
                orElse: () => '',
              );

              if (otherUid.isEmpty) {
                return const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.error_outline)),
                  title: Text('Invalid chat'),
                  subtitle: Text('Missing participants'),
                );
              }

              final otherName = _safeOtherName(data, otherUid);
              final lastMessage =
                  (data['lastMessage'] ?? '').toString().trim();
              final lastSenderId =
                  (data['lastSenderId'] ?? '').toString();

              final unread =
                  (data['unreadCount']?[me.uid] ?? 0) as int;

              final subtitle = lastMessage.isEmpty
                  ? 'No messages yet'
                  : (lastSenderId == me.uid
                      ? 'You: $lastMessage'
                      : lastMessage);

              final timeText = _formatTimestamp(data['lastMessageAt']);

              return ListTile(
                leading: CircleAvatar(
                  child: Text(_initialLetter(otherName)),
                ),
                title: Text(
                  otherName,
                  style: unread > 0
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: unread > 0
                      ? const TextStyle(fontWeight: FontWeight.w600)
                      : null,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoom(
                        chatId: doc.id,
                        otherUid: otherUid,
                        otherName: otherName,
                      ),
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
