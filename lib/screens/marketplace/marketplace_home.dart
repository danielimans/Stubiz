import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import 'product_detail.dart';
import 'add_product.dart';
import 'marketplace_search.dart';

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  final categories = [
    'All',
    'Books',
    'Electronics',
    'Stationery',
    'Services',
    'Others',
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          _categoryChips(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: FirestoreService.streamAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = _applyCategory(snapshot.data!);

                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.storefront,
                    title: 'No Products Found',
                    message: 'Try changing category.',
                    actionText: 'View All',
                    onAction: () {
                      setState(() => _selectedCategory = 'All');
                    },
                  );
                }

                return AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        columnCount: 2,
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _productCard(product),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FILTER
  // =====================================================

  List<Product> _applyCategory(List<Product> products) {
    return products.where((p) {
      return _selectedCategory == 'All' ||
          p.category == _selectedCategory;
    }).toList();
  }

  // =====================================================
  // UI
  // =====================================================

  Widget _categoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: categories.map((cat) {
          final selected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FilterChip(
              label: Text(cat),
              selected: selected,
              selectedColor: Colors.blue.shade400,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
              onSelected: (_) =>
                  setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _productCard(Product product) {
    final user = AuthService.currentUser;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetail(product: product),
            ),
          );
        },
        onLongPress: user?.uid == product.ownerId
            ? () => _showOwnerOptions(product)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(product),
            Expanded(child: _infoSection(product)),
          ],
        ),
      ),
    );
  }

  Widget _imageSection(Product product) {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? Image.network(product.imageUrl!, fit: BoxFit.contain)
              : Icon(Icons.image,
                  size: 48, color: Colors.grey.shade400),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _badge(product.category),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _favoriteButton(product),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _favoriteButton(Product product) {
    final user = AuthService.currentUser;

    return GestureDetector(
      onTap: user == null
          ? null
          : () async {
              final fav = product.isFavorite;
              setState(() => product.isFavorite = !fav);

              if (fav) {
                await FirestoreService.removeFromFavorites(
                    user.uid, product.id);
              } else {
                await FirestoreService.addToFavorites(
                    user.uid, product.id);
              }
            },
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(
          product.isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          color: product.isFavorite ? Colors.red : Colors.grey,
        ),
      ),
    );
  }

  Widget _infoSection(Product product) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            'RM ${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ACTIONS
  // =====================================================

  void _addProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProduct()),
    );
  }

  void _showOwnerOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProduct(product: product),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await FirestoreService.deleteProduct(product.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: MarketplaceSearch(),
    );
  }
}
