import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart' as adminOrder;
import '../models/user.dart';
import '../models/category.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'dart:html' as html;
import 'dart:async';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/order_service.dart';

class AppProvider extends ChangeNotifier {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final OrderService _orderService = OrderService();

  bool _isUploadingImages = false;
  bool get isUploadingImages => _isUploadingImages;

  void setUploadingImages(bool value) {
    _isUploadingImages = value;
    notifyListeners();
  }

  Stream<bool> get loadingStream => _productService.loadingStream;
  Stream<String?> get errorStream => _productService.errorStream;
  Stream<String?> get successStream => _productService.successStream;

  final ValueNotifier<Set<Category>> uniqueCategoriesNotifier =
      ValueNotifier<Set<Category>>({});

  @override
  void dispose() {
    _productService.dispose();
    _categoryService.dispose();
    _orderService.dispose();
    uniqueCategoriesNotifier.dispose();
    super.dispose();
  }

  // Add constructor to initialize public category
  AppProvider() {
    _initializePublicCategory();
    _setupCategoryListener();
  }

  void _setupCategoryListener() {
    categoriesStream.listen((categories) {
      uniqueCategoriesNotifier.value = categories.toSet();
    });
  }

  Future<void> _initializePublicCategory() async {
    await _categoryService.ensurePublicCategory();
  }

  // Product Management
  Future<List<Product>> getProducts() => _productService.getProducts();

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required List<String> images,
    required bool isHot,
    required bool isNew,
    required bool onSale,
    double? salePrice,
  }) {
    return _productService.addProduct(
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      images: images,
      isHot: isHot,
      isNew: isNew,
      onSale: onSale,
      salePrice: salePrice,
    );
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required List<String> images,
    required bool isHot,
    required bool isNew,
    required bool onSale,
    double? salePrice,
  }) async {
    return _productService.updateProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      images: images,
      isHot: isHot,
      isNew: isNew,
      onSale: onSale,
      salePrice: salePrice,
    );
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final product =
          await _firestore.collection('products').doc(productId).get();

      if (product.exists) {
        final imageUrls = List<String>.from(product.data()?['imageUrls'] ?? []);
        await _firestore.collection('products').doc(productId).delete();

        for (final imageUrl in imageUrls) {
          final ref = storage.FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Stream<List<Product>> get productsStream => _productService.productsStream;

  // Category Management
  Future<List<Category>> getCategories() => _categoryService.getCategories();

  Future<List<Product>> getProductsByCategory(String categoryId) =>
      _categoryService.getProductsByCategory(categoryId);

  Future<bool> addCategory(Category category) =>
      _categoryService.addCategory(category);

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
  }) {
    return _categoryService.updateCategory(
      id: id,
      name: name,
      imageUrl: imageUrl,
    );
  }

  // Update delete category method to prevent public category deletion
  Future<bool> deleteCategory(String categoryId) async {
    try {
      // Get category to access image URL
      final category =
          await _firestore.collection('categories').doc(categoryId).get();

      if (category.exists) {
        final imageUrl = category.data()?['imageUrl'] as String?;

        // Delete category document
        await _firestore.collection('categories').doc(categoryId).delete();

        // Delete image from storage if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final ref = storage.FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  Future<bool> deleteCategoryAndMoveProducts(
    String fromCategoryId,
    String toCategoryId,
  ) =>
      _categoryService.deleteCategoryAndMoveProducts(
        fromCategoryId,
        toCategoryId,
      );

  Future<bool> categoryHasProducts(String categoryId) async {
    final products = await getProductsByCategory(categoryId);
    return products.isNotEmpty;
  }

  Future<bool> updateProductCategory(
    String productId,
    String newCategoryId,
  ) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({'categoryId': newCategoryId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Category>> get categoriesStream =>
      _categoryService.categoriesStream;

  // Order Management
  Stream<List<adminOrder.Order>> get ordersStream {
    return _orderService.ordersStream.map((orders) =>
        orders.map((o) => adminOrder.Order.fromMap(o.toMap())).toList());
  }

  Future<bool> updateOrderStatus(String orderId, String status) =>
      _orderService.updateOrderStatus(orderId, status);

  Future<adminOrder.Order?> getOrderById(String orderId) async {
    final order = await _orderService.getOrderById(orderId);
    return order == null ? null : adminOrder.Order.fromMap(order.toMap());
  }

  Future<List<adminOrder.Order>> getOrdersByUserId(String userId) async {
    final orders = await _orderService.getOrdersByUserId(userId);
    return orders.map((o) => adminOrder.Order.fromMap(o.toMap())).toList();
  }

  // Generic Image Upload Function
  Future<List<String>> uploadImages({
    required List<html.File> files,
    required String folder, // 'products' or 'categories'
  }) async {
    setUploadingImages(true);
    final urls = <String>[];

    try {
      for (final file in files) {
        final ref = storage.FirebaseStorage.instance.ref().child(
              'images/$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            );

        final metadata = storage.SettableMetadata(
          contentType: file.type,
          customMetadata: {'picked-file-path': file.name},
        );

        await ref.putBlob(file, metadata);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
    } finally {
      setUploadingImages(false);
    }

    return urls;
  }

  // Helper methods for specific uploads
  Future<List<String>> uploadProductImages(List<html.File> files) {
    return uploadImages(files: files, folder: 'products');
  }

  Future<String> uploadCategoryImage(html.File file) async {
    final urls = await uploadImages(files: [file], folder: 'categories');
    return urls.first;
  }

  // Users Stream
  Stream<List<AppUser>> get usersStream {
    return _firestore.collection('users').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList(),
        );
  }

  // Dashboard Data Stream
  Stream<Map<String, dynamic>> get dashboardDataStream {
    return _firestore.collection('dashboard').doc('stats').snapshots().map(
          (doc) => doc.data() ?? {},
        );
  }

  Future<bool> deleteProductImage(String productId, String imageUrl) async {
    try {
      // Delete from storage
      final ref = storage.FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      // Update product document
      await _firestore.collection('products').doc(productId).update({
        'imageUrls': fs.FieldValue.arrayRemove([imageUrl])
      });

      return true;
    } catch (e) {
      print('Error deleting product image: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      // Add any initialization logic here
      // For example:
      // - Load initial data
      // - Check authentication
      // - Initialize services
      await Future.delayed(
          const Duration(seconds: 1)); // Simulated initialization
    } catch (e) {
      debugPrint('Initialization error: $e');
      rethrow;
    }
  }
}
