import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart' as storage;

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _loadingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String?>.broadcast();
  final _successController = StreamController<String?>.broadcast();

  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<String?> get successStream => _successController.stream;

  void dispose() {
    _loadingController.close();
    _errorController.close();
    _successController.close();
  }

  Stream<List<Product>> get productsStream {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList());
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    String? categoryId,
    required List<String> images,
    required bool isHot,
    required bool isNew,
    required bool onSale,
    double? salePrice,
  }) async {
    _loadingController.add(true);
    try {
      String finalCategoryId = categoryId ?? await _getPublicCategoryId();

      final product = Product(
        id: _firestore.collection('products').doc().id,
        name: name,
        description: description,
        price: price,
        salePrice: salePrice,
        categoryId: finalCategoryId,
        isHot: isHot,
        isNew: isNew,
        onSale: onSale,
        createdAt: DateTime.now(),
        imageUrls: images,
      );

      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap());

      _successController.add('Product added successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to add product: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<String> _getPublicCategoryId() async {
    final snapshot = await _firestore
        .collection('categories')
        .where('name', isEqualTo: 'Public')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final publicCategory = Category(
        id: _firestore.collection('categories').doc().id,
        name: 'Public',
        imageUrl: '',
      );
      await _firestore
          .collection('categories')
          .doc(publicCategory.id)
          .set(publicCategory.toMap());
      return publicCategory.id;
    }

    return snapshot.docs.first.id;
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    String? categoryId,
    required List<String> images,
    required bool isHot,
    required bool isNew,
    required bool onSale,
    double? salePrice,
  }) async {
    _loadingController.add(true);
    try {
      // Get current product to compare images
      final doc = await _firestore.collection('products').doc(id).get();
      if (!doc.exists) return false;

      final currentProduct = Product.fromMap(doc.data()!);

      // Find images that were removed
      final removedImages = currentProduct.imageUrls
          .where((oldUrl) => !images.contains(oldUrl))
          .toList();

      // Delete removed images from storage
      for (final imageUrl in removedImages) {
        try {
          final ref = storage.FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed to delete old image: $e');
        }
      }

      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        salePrice: salePrice,
        categoryId: categoryId ?? await _getPublicCategoryId(),
        imageUrls: images,
        isHot: isHot,
        isNew: isNew,
        onSale: onSale,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('products').doc(id).update(product.toMap());
      _successController.add('Product updated successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to update product: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<bool> deleteProduct(String id) async {
    _loadingController.add(true);
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (!doc.exists) return false;

      final product = Product.fromMap(doc.data()!);

      // Delete all product images from storage
      for (final imageUrl in product.imageUrls) {
        try {
          final imageRef =
              storage.FirebaseStorage.instance.refFromURL(imageUrl).fullPath;
          // Ensure we're only deleting from images/products folder
          if (imageRef.startsWith('images/products/')) {
            final ref = storage.FirebaseStorage.instance.ref(imageRef);
            await ref.delete();
          }
        } catch (e) {
          print('Failed to delete product image: $e');
        }
      }

      await _firestore.collection('products').doc(id).delete();
      return true;
    } catch (e) {
      _errorController.add('Failed to delete product: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      _errorController.add('Failed to fetch products: $e');
      return [];
    }
  }
}
