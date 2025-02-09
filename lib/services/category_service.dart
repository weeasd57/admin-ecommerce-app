import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart' as storage;

class CategoryService {
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

  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _errorController.add('Failed to fetch categories: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      _errorController.add('Failed to fetch products by category: $e');
      return [];
    }
  }

  Future<bool> addCategory(Category category) async {
    _loadingController.add(true);
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .set(category.toMap());
      _successController.add('Category added successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to add category: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
  }) async {
    _loadingController.add(true);
    try {
      // Get current category to compare images
      final doc = await _firestore.collection('categories').doc(id).get();
      if (!doc.exists) return false;

      final currentCategory = Category.fromMap(id, doc.data()!);

      // If image URL changed, delete old image
      if (currentCategory.imageUrl != imageUrl &&
          currentCategory.imageUrl.isNotEmpty) {
        try {
          final ref = storage.FirebaseStorage.instance
              .refFromURL(currentCategory.imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed to delete old category image: $e');
        }
      }

      await _firestore.collection('categories').doc(id).update({
        'name': name,
        'imageUrl': imageUrl,
      });

      _successController.add('Category updated successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to update category: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    _loadingController.add(true);
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (!doc.exists) return false;

      final category = Category.fromMap(categoryId, doc.data()!);

      // Delete category image from storage if it exists
      if (category.imageUrl.isNotEmpty) {
        try {
          final imageRef = storage.FirebaseStorage.instance
              .refFromURL(category.imageUrl)
              .fullPath;
          // Ensure we're only deleting from images/categories folder
          if (imageRef.startsWith('images/categories/')) {
            final ref = storage.FirebaseStorage.instance.ref(imageRef);
            await ref.delete();
          }
        } catch (e) {
          print('Failed to delete category image: $e');
        }
      }

      await _firestore.collection('categories').doc(categoryId).delete();
      return true;
    } catch (e) {
      _errorController.add('Failed to delete category: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<bool> deleteCategoryAndMoveProducts(
    String fromCategoryId,
    String toCategoryId,
  ) async {
    _loadingController.add(true);
    try {
      final products = await getProductsByCategory(fromCategoryId);
      final categoryDoc =
          await _firestore.collection('categories').doc(fromCategoryId).get();
      final category = Category.fromMap(fromCategoryId, categoryDoc.data()!);

      // Delete category image
      if (category.imageUrl.isNotEmpty) {
        try {
          final ref =
              storage.FirebaseStorage.instance.refFromURL(category.imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed to delete category image: $e');
        }
      }

      // Update all products to new category
      final batch = _firestore.batch();
      for (final product in products) {
        final productRef = _firestore.collection('products').doc(product.id);
        batch.update(productRef, {'categoryId': toCategoryId});
      }

      // Delete the category
      final categoryRef =
          _firestore.collection('categories').doc(fromCategoryId);
      batch.delete(categoryRef);

      await batch.commit();
      _successController
          .add('Category deleted and products moved successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to delete category and move products: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Stream<List<Category>> get categoriesStream {
    return _firestore.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Add method to ensure public category exists
  Future<void> ensurePublicCategory() async {
    try {
      // Check if public category exists (case-insensitive)
      final snapshot = await _firestore
          .collection('categories')
          .where('name', isEqualTo: 'Public')
          .get();

      // If no public category exists, create one
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
      } else if (snapshot.docs.length > 1) {
        // If multiple public categories exist, keep only the first one
        final docsToDelete = snapshot.docs.skip(1);
        final batch = _firestore.batch();
        for (var doc in docsToDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      _errorController.add('Failed to ensure public category: $e');
    }
  }
}
