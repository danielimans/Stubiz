import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  // =========================
  // CORE FIELDS
  // =========================
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String? imageUrl;

  // =========================
  // OWNERSHIP (MANDATORY)
  // =========================
  final String ownerId;
  final String ownerName;

  // =========================
  // STATE
  // =========================
  final bool isActive;     // Stored in Firestore
  bool isFavorite;         // UI-only (never written)

  // =========================
  // METADATA
  // =========================
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.ownerId,
    required this.ownerName,
    this.imageUrl,
    this.isActive = true,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  }) {
    // =========================
    // HARD GUARDS (FAIL FAST)
    // =========================
    if (ownerId.trim().isEmpty) {
      throw ArgumentError('ownerId must not be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title must not be empty');
    }
  }

  // ======================================================
  // FROM FIRESTORE
  // ======================================================
  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Product document ${doc.id} is empty');
    }

    final ownerId = (data['ownerId'] ?? '').toString().trim();
    if (ownerId.isEmpty) {
      throw StateError('Product ${doc.id} has invalid ownerId');
    }

    return Product(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? 'Others').toString(),
      imageUrl: data['imageUrl'] as String?,
      ownerId: ownerId,
      ownerName: (data['ownerName'] ?? 'Business Owner').toString(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // ======================================================
  // TO FIRESTORE (WRITE-SAFE)
  // ======================================================
  Map<String, dynamic> toFirestore({required bool isNew}) {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isActive': isActive,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ======================================================
  // FROM JSON (LOCAL CACHE / FAVORITES ONLY)
  // ======================================================
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // ======================================================
  // TO JSON (LOCAL CACHE ONLY)
  // ======================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isActive': isActive,
      'isFavorite': isFavorite,
    };
  }

  // ======================================================
  // COPY
  // ======================================================
  Product copyWith({
    String? title,
    double? price,
    String? description,
    String? category,
    String? imageUrl,
    bool? isActive,
    bool? isFavorite,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId,
      ownerName: ownerName,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
