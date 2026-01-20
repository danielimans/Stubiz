import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import 'product_detail.dart';

class MarketplaceSearch extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search products';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResults();
  }

  Widget _buildResults() {
    final q = query.trim();

    if (q.isEmpty) {
      return const Center(
        child: Text(
          'Type to search products',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<Product>>(
      future: FirestoreService.searchProducts(q),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Search failed:\n${snap.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final products = snap.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = products[i];

            return ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(p.title),
              subtitle: Text('RM ${p.price.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                close(context, null); // close search properly
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetail(product: p),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
