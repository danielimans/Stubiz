import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';

class AddProduct extends StatefulWidget {
  final Product? product;

  const AddProduct({super.key, this.product});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _categories = const [
    'Books',
    'Electronics',
    'Stationery',
    'Services',
    'Others',
  ];

  String _category = 'Books';

  File? _pickedImage;
  String? _imageUrl;
  bool _loading = false;

  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _titleCtrl.text = p.title;
      _priceCtrl.text = p.price.toStringAsFixed(2);
      _descCtrl.text = p.description;
      _category = p.category;
      _imageUrl = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // IMAGE
  // =====================================================

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<String?> _uploadImage(String productId) async {
    if (_pickedImage == null) return _imageUrl;

    final ref = _storage.ref('products/$productId.jpg');
    await ref.putFile(_pickedImage!);
    return await ref.getDownloadURL();
  }

  // =====================================================
  // SAVE
  // =====================================================

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty) {
      _toast('Please fill all fields');
      return;
    }

    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      _toast('Invalid price');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('Please login');
      return;
    }

    setState(() => _loading = true);

    try {
      final productId =
          widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await _uploadImage(productId);

      final product = Product(
        id: productId,
        title: _titleCtrl.text.trim(),
        price: price,
        description: _descCtrl.text.trim(),
        category: _category,
        imageUrl: imageUrl,
        ownerId: user.uid, 
        ownerName: user.displayName ?? 'Student Seller',
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt,
      );

      if (_isEdit) {
        await FirestoreService.updateProduct(product);
      } else {
        await FirestoreService.createProduct(product);
      }

      if (mounted) {
        Navigator.pop(context, product);
      }
    } catch (e) {
      _toast('Failed to save product');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imagePicker(),
            const SizedBox(height: 24),
            _field('Product Title', _titleCtrl),
            _dropdown(),
            _priceField(),
            _field('Description', _descCtrl, maxLines: 4),
            const SizedBox(height: 32),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: _loading ? null : _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _pickedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_pickedImage!, fit: BoxFit.cover),
              )
            : _imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrl!, fit: BoxFit.cover),
                  )
                : const Center(
                    child:
                        Icon(Icons.add_photo_alternate_outlined, size: 48),
                  ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _category,
        items: _categories
            .map(
              (c) => DropdownMenuItem(value: c, child: Text(c)),
            )
            .toList(),
        onChanged: _loading ? null : (v) => setState(() => _category = v!),
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _priceField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _priceCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: 'Price (RM)',
          prefixText: 'RM ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isEdit ? 'Update Product' : 'Post Product'),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
