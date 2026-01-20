import 'package:flutter/material.dart';
import 'package:stubiz_main/screens/marketplace/marketplace_home.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../marketplace/product_detail.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Favorites')),
        body: const Center(
          child: Text('Please login to view your favorites'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.streamUserFavorites(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data!;

          if (favorites.isEmpty) {
            return _emptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = favorites[index];
              return _favoriteCard(context, product, user.uid);
            },
          );
        },
      ),
    );
  }

  // =====================================================
  // UI COMPONENTS
  // =====================================================

  Widget _favoriteCard(
    BuildContext context,
    Product product,
    String userId,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetail(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _productImage(product.imageUrl),
              const SizedBox(width: 12),
              Expanded(child: _productInfo(product)),
              _removeButton(context, product, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productImage(String? imageUrl) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image, color: Colors.grey.shade400),
              ),
            )
          : Icon(Icons.image, color: Colors.grey.shade400),
    );
  }

  Widget _productInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.category,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          'RM ${product.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _removeButton(
    BuildContext context,
    Product product,
    String userId,
  ) {
    return IconButton(
      icon: Icon(Icons.favorite, color: Colors.red.shade500),
      onPressed: () async {
        try {
          await FirestoreService.removeFromFavorites(userId, product.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Removed from favorites'),
                duration: Duration(milliseconds: 900),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  // =====================================================
  // EMPTY / ERROR STATES
  // =====================================================

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceHome()),
              );
            },
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
