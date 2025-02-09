class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? shippingAddress;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.shippingAddress,
    this.paymentMethod,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      userId: map['userId'] as String,
      items: (map['items'] as List).map((item) => OrderItem.fromMap(item)).toList(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      shippingAddress: map['shippingAddress'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
