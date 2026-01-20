import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/exchange_item.dart';
import '../../services/auth_service.dart';

class ExchangeForm extends StatefulWidget {
  final ExchangeItem? item;
  const ExchangeForm({super.key, this.item});

  @override
  State<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends State<ExchangeForm> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final wantedCtrl = TextEditingController();

  final categories = ['Books', 'Electronics', 'Stationery', 'Others'];
  String selectedCategory = 'Books';

  bool saving = false;
  String errorText = '';

  // images
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _newImages = [];
  final List<String> _existingUrls = [];

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    if (it != null) {
      titleCtrl.text = it.title;
      descCtrl.text = it.description;
      wantedCtrl.text = it.wantedItem;
      selectedCategory = it.category;
      _existingUrls.addAll(it.imageUrls);
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    wantedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _newImages.addAll(files));
  }

  void _removeNewAt(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingAt(int index) {
    setState(() => _existingUrls.removeAt(index));
  }

  Future<void> _submit() async {
    setState(() {
      saving = true;
      errorText = '';
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Not logged in.');
      }

      final name = titleCtrl.text.trim();
      final wanted = wantedCtrl.text.trim();
      final desc = descCtrl.text.trim();

      if (name.isEmpty || wanted.isEmpty || desc.isEmpty) {
        throw Exception('Please fill all fields.');
      }

      // Create doc id first (for storage folder)
      final posts = FirebaseFirestore.instance.collection('exchange_posts');
      final docRef = widget.item == null
          ? posts.doc()
          : posts.doc(widget.item!.id);

      // Upload newly selected images to storage
      final uploadedUrls = <String>[];
      for (final x in _newImages) {
        final file = File(x.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${x.name}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'exchange_posts/${user.uid}/${docRef.id}/$fileName',
        );

        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        uploadedUrls.add(url);
      }

      final allUrls = <String>[..._existingUrls, ...uploadedUrls];

      final thumbnail = allUrls.isNotEmpty ? allUrls.first : null;

      final displayName = (user.displayName ?? '').trim();

      final now = FieldValue.serverTimestamp();

      if (widget.item == null) {
        await docRef.set({
          'title': name,
          'description': desc,
          'wantedItem': wanted,
          'category': selectedCategory,
          'ownerId': user.uid,
          'ownerName': displayName,
          'thumbnailUrl': thumbnail,
          'imageUrls': allUrls,
          'createdAt': now,
          'updatedAt': now,
        });
      } else {
        await docRef.update({
          'title': name,
          'description': desc,
          'wantedItem': wanted,
          'category': selectedCategory,
          'thumbnailUrl': thumbnail,
          'imageUrls': allUrls,
          'updatedAt': now,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => errorText = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Exchange Post' : 'Add Exchange Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: wantedCtrl,
              decoration: const InputDecoration(labelText: 'Wanted Item'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),

            // ===== Images Section =====
            Row(
              children: [
                const Text(
                  'Images',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: saving ? null : _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_existingUrls.isEmpty && _newImages.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No images selected.'),
              ),

            if (_existingUrls.isNotEmpty || _newImages.isNotEmpty)
              _buildImageGrid(),

            if (errorText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(errorText, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _submit,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update' : 'Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    // combine to show previews
    final tiles = <Widget>[];

    // existing urls
    for (int i = 0; i < _existingUrls.length; i++) {
      final url = _existingUrls[i];
      tiles.add(
        _thumb(
          child: Image.network(url, fit: BoxFit.cover),
          onRemove: saving ? null : () => _removeExistingAt(i),
        ),
      );
    }

    // new local images
    for (int i = 0; i < _newImages.length; i++) {
      final xf = _newImages[i];
      tiles.add(
        _thumb(
          child: Image.file(File(xf.path), fit: BoxFit.cover),
          onRemove: saving ? null : () => _removeNewAt(i),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget _thumb({required Widget child, required VoidCallback? onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
