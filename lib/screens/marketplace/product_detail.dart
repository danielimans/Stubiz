import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_room.dart';

class ProductDetail extends StatefulWidget {
  final Product product;

  const ProductDetail({super.key, required this.product});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late Product product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    _init();
  }

  Future<void> _init() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        product.isFavorite =
            await FirestoreService.isFavorite(user.uid, product.id);
      } catch (_) {
        product.isFavorite = false;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // =====================================================
  // CHAT OWNER (SAFE)
  // =====================================================

  Future<void> _chatOwner() async {
    final me = AuthService.currentUser;

    if (me == null) {
      _toast('Please login first');
      return;
    }

    if (product.ownerId.trim().isEmpty) {
      _toast('Seller information not available');
      return;
    }

    if (me.uid == product.ownerId) {
      _toast('You cannot chat with yourself');
      return;
    }

    final participants = [me.uid, product.ownerId]..sort();
    final chatId = participants.join('_');

    if (!mounted) return;

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
  }

  // =====================================================
  // FAVORITE (ROLLBACK-SAFE)
  // =====================================================

  Future<void> _toggleFavorite() async {
    final user = AuthService.currentUser;
    if (user == null) {
      _toast('Please login first');
      return;
    }

    final newValue = !product.isFavorite;
    setState(() => product.isFavorite = newValue);

    try {
      if (newValue) {
        await FirestoreService.addToFavorites(user.uid, product.id);
      } else {
        await FirestoreService.removeFromFavorites(user.uid, product.id);
      }
    } catch (e) {
      // rollback
      setState(() => product.isFavorite = !newValue);
      _toast('Failed to update favorite');
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(),
                  const SizedBox(height: 12),
                  _price(),
                  const SizedBox(height: 16),
                  _category(),
                  const SizedBox(height: 24),
                  _description(),
                  const SizedBox(height: 32),
                  _ownerInfo(),
                  const SizedBox(height: 24),
                  _chatButton(),
                  const SizedBox(height: 16),
                  _favoriteButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SECTIONS
  // =====================================================

  Widget _imageSection() {
    return Hero(
      tag: 'product-${product.id}',
      child: Container(
        height: 320,
        width: double.infinity,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Icon(Icons.image, size: 80, color: Colors.grey.shade400);
  }

  Widget _title() {
    return Text(
      product.title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _price() {
    return Text(
      'RM ${product.price.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _category() {
    return Chip(
      label: Text(product.category),
      backgroundColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _description() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ],
    );
  }

  Widget _ownerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, size: 32, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.ownerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'UTHM Campus',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chatButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat Owner'),
        onPressed: _chatOwner,
      ),
    );
  }

  Widget _favoriteButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: Icon(
          product.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: product.isFavorite ? Colors.red : Colors.grey,
        ),
        label: Text(
          product.isFavorite ? 'Favorited' : 'Add to Favorites',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
