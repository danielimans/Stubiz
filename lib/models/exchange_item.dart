import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeItem {
  final String id;
  final String title;
  final String description;
  final String wantedItem;
  final String category;

  final String ownerId;
  final String ownerName;

  final String? thumbnailUrl;
  final List<String> imageUrls;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ExchangeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.wantedItem,
    required this.category,
    required this.ownerId,
    required this.ownerName,
    required this.thumbnailUrl,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExchangeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final urls = (data['imageUrls'] is List)
        ? (data['imageUrls'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return ExchangeItem(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      wantedItem: (data['wantedItem'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] as String?),
      imageUrls: urls,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'wantedItem': wantedItem,
    'category': category,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'thumbnailUrl': thumbnailUrl,
    'imageUrls': imageUrls,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
