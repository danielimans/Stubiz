import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class ChatService {
  static String buildChatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  static Future<String> getOrCreateChat({
    required String otherUid,
    required String otherName,
  }) async {
    final me = AuthService.currentUser;
    if (me == null) throw Exception('Not logged in.');

    final chatId = buildChatId(me.uid, otherUid);
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final snap = await ref.get();
    if (snap.exists) return chatId;

    await ref.set({
      'participants': [me.uid, otherUid],
      'participantNames': {
        me.uid: (me.displayName ?? '').toString(),
        otherUid: otherName,
      },
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatId;
  }
}
