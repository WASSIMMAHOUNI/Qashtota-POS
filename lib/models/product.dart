class Product {
  final int? id;
  final String name;
  final String category;
  final int price;
  final int stock;
  final String emoji;
  final String? imagePath;

  const Product({this.id, required this.name, required this.category, required this.price, required this.stock, required this.emoji, this.imagePath});

  Product copyWith({int? id, String? name, String? category, int? price, int? stock, String? emoji, String? imagePath}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'category': category, 'price': price, 'stock': stock, 'emoji': emoji, 'image_path': imagePath};

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        price: map['price'] as int,
        stock: map['stock'] as int,
        emoji: map['emoji'] as String,
        imagePath: map['image_path'] as String?,
      );
}
