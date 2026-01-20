import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../chat/chat_room.dart';

class PromotionDetail extends StatelessWidget {
  final Product product;

  const PromotionDetail({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerImage(product.imageUrl),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // OWNER
                  Text(
                    'by ${product.ownerName}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 6),

                  // CATEGORY
                  Chip(
                    label: Text(product.category),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DESCRIPTION
                  const Text(
                    'About This Business',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CHAT BUTTON
                  _chatButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // IMAGE
  // =====================================================

  Widget _headerImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront, size: 64),
      );
    }

    return Image.network(
      imageUrl,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 220,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront, size: 64),
      ),
    );
  }

  // =====================================================
  // CHAT OWNER
  // =====================================================

  Widget _chatButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.chat),
        label: const Text('Chat Owner'),
        onPressed: () {
          final me = AuthService.currentUser;

          if (me == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login first')),
            );
            return;
          }

          if (me.uid == product.ownerId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You cannot chat with yourself')),
            );
            return;
          }

          final participants = [me.uid, product.ownerId]..sort();
          final chatId = participants.join('_');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoom(
                chatId: chatId,
                otherUid: product.ownerId,
                otherName: product.ownerName,
              ),
            ),
          );
        },
      ),
    );
  }
}
