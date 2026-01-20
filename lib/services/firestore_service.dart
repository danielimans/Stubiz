import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= PRODUCTS =================

  static Stream<List<Product>> streamAllProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  static Stream<List<Product>> streamMyProducts(String ownerId) {
    if (ownerId.trim().isEmpty) return const Stream.empty();

    return _db
        .collection('products')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  static Future<Product?> getProduct(String productId) async {
    if (productId.trim().isEmpty) return null;
    final doc = await _db.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  static Future<void> createProduct(Product product) async {
    await _db
        .collection('products')
        .doc(product.id)
        .set(product.toFirestore(isNew: true));
  }

  static Future<void> updateProduct(Product product) async {
    await _db
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore(isNew: false));
  }

  static Future<void> deactivateProduct(String productId) async {
    await _db.collection('products').doc(productId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  static Future<List<Product>> searchProducts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final snap = await _db
        .collection('products')
        .orderBy('title')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .get();

    return snap.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  static Stream<List<Product>> streamProductsByCategory(String category) {
    if (category.trim().isEmpty) return const Stream.empty();

    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // ================= FAVORITES =================

  static Stream<List<Product>> streamUserFavorites(String userId) {
    if (userId.trim().isEmpty) return const Stream.empty();

    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .asyncMap((snap) async {
          final products = <Product>[];
          for (final fav in snap.docs) {
            final product = await getProduct(fav.id);
            if (product != null) {
              product.isFavorite = true;
              products.add(product);
            }
          }
          return products;
        });
  }

  static Future<void> addToFavorites(String userId, String productId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .set({
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromFavorites(
      String userId, String productId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  static Future<bool> isFavorite(String userId, String productId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .get();
    return doc.exists;
  }

  // ================= CHATS =================

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamUserChats(
      String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamChatMessages(
      String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': message,
      'type': 'text',
      'createdAt': now,
      'status': 'sent',
    });

    batch.set(
      chatRef,
      {
        'lastMessage': message,
        'lastMessageAt': now,
        'lastSenderId': senderId,
        'unreadCount': {
          senderId: 0,
          receiverId: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Future<void> markChatAsRead(
      String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  // ✅ SAFE: no compound query, no index required
  static Future<void> markMessagesDelivered(
      String chatId, String userId) async {
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _db.batch();

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status'];
      final senderId = data['senderId'];

      if (senderId != userId && status == 'sent') {
        batch.update(doc.reference, {'status': 'delivered'});
      }
    }

    await batch.commit();
  }

  // ✅ SAFE: handles missing status field
  static Future<void> markMessagesSeen(
      String chatId, String userId) async {
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _db.batch();

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status'];
      final senderId = data['senderId'];

      if (senderId != userId &&
          (status == 'sent' || status == 'delivered')) {
        batch.update(doc.reference, {'status': 'seen'});
      }
    }

    await batch.commit();
  }

  static Stream<int> totalUnreadChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['unreadCount']?[userId] ?? 0) as int;
      }
      return total;
    });
  }

  // ================= EXCHANGES =================

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      streamMyExchangesAsRequester(String userId) {
    return _db
        .collection('exchanges')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      streamMyExchangesAsOwner(String userId) {
    return _db
        .collection('exchanges')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<String> createExchange({
    required String requesterId,
    required String requesterName,
    required String ownerId,
    required String ownerName,
    required String productId,
    required String productTitle,
    required String wantedItem,
    required String category,
    String? thumbnailUrl,
  }) async {
    final docRef = _db.collection('exchanges').doc();

    await docRef.set({
      'id': docRef.id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'productId': productId,
      'productTitle': productTitle,
      'wantedItem': wantedItem,
      'category': category,
      'thumbnailUrl': thumbnailUrl ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  static Future<void> updateExchangeStatus(
      String exchangeId, String status) async {
    await _db.collection('exchanges').doc(exchangeId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
