import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as admin_order;
import 'dart:async';

class OrderService {
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

  Stream<List<admin_order.Order>> get ordersStream {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<admin_order.Order>>(
          (snapshot) => snapshot.docs
              .map((doc) => admin_order.Order.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _loadingController.add(true);
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _successController.add('Order status updated successfully');
      return true;
    } catch (e) {
      _errorController.add('Failed to update order status: $e');
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<admin_order.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return admin_order.Order.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _errorController.add('Failed to fetch order: $e');
      return null;
    }
  }

  Future<List<admin_order.Order>> getOrdersByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map<admin_order.Order>(
              (doc) => admin_order.Order.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _errorController.add('Failed to fetch user orders: $e');
      return [];
    }
  }
}
