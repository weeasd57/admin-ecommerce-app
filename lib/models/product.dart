class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? categoryId;
  final List<String> imageUrls;
  final bool isHot;
  final bool isNew;
  final bool onSale;
  final double? salePrice;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.categoryId,
    required this.imageUrls,
    this.isHot = false,
    this.isNew = false,
    this.onSale = false,
    this.salePrice,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      categoryId: map['categoryId'] as String?,
      imageUrls: List<String>.from(map['imageUrls'] as List),
      isHot: map['isHot'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? false,
      onSale: map['onSale'] as bool? ?? false,
      salePrice: map['salePrice'] != null
          ? (map['salePrice'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrls': imageUrls,
      'isHot': isHot,
      'isNew': isNew,
      'onSale': onSale,
      'salePrice': salePrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    List<String>? imageUrls,
    bool? isHot,
    bool? isNew,
    bool? onSale,
    double? salePrice,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrls: imageUrls ?? this.imageUrls,
      isHot: isHot ?? this.isHot,
      isNew: isNew ?? this.isNew,
      onSale: onSale ?? this.onSale,
      salePrice: salePrice ?? this.salePrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
