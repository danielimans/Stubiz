import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import 'promotion_detail.dart';

class PromotionHome extends StatelessWidget {
  const PromotionHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Businesses'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.streamAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Defensive filter: active + valid data
          final products = (snapshot.data ?? [])
              .where(
                (p) =>
                    p.isActive &&
                    p.ownerId.trim().isNotEmpty &&
                    p.title.trim().isNotEmpty,
              )
              .toList();

          if (products.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _productCard(context, products[index]);
            },
          );
        },
      ),
    );
  }

  // =====================================================
  // PRODUCT CARD
  // =====================================================

  Widget _productCard(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PromotionDetail(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(product.imageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _image(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _imageFallback();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.network(
        imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, size: 48),
    );
  }

  // =====================================================
  // STATES
  // =====================================================

  Widget _emptyState() {
    return const Center(
      child: Text(
        'No student businesses available',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
