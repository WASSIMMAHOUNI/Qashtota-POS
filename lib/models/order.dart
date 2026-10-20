class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String name;
  final String emoji;
  final String? imagePath;
  final int price;
  final int qty;

  const OrderItem({this.id, required this.orderId, required this.productId, required this.name, required this.emoji, this.imagePath, required this.price, required this.qty});

  int get lineTotal => price * qty;

  Map<String, dynamic> toMap() => {'id': id, 'order_id': orderId, 'product_id': productId, 'name': name, 'emoji': emoji, 'image_path': imagePath, 'price': price, 'qty': qty};

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        id: map['id'] as int?,
        orderId: map['order_id'] as int,
        productId: map['product_id'] as int,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        imagePath: map['image_path'] as String?,
        price: map['price'] as int,
        qty: map['qty'] as int,
      );
}

class PosOrder {
  final int? id;
  final DateTime createdAt;
  final int subtotal;
  final int tax;
  final int total;
  final String payMethod;
  final int paid;
  final int change;
  final bool isFree;
  final List<OrderItem> items;

  const PosOrder({this.id, required this.createdAt, required this.subtotal, required this.tax, required this.total, required this.payMethod, required this.paid, required this.change, this.isFree = false, required this.items});

  Map<String, dynamic> toMap() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'pay_method': payMethod,
        'paid': paid,
        'change_amount': change,
        'is_free': isFree ? 1 : 0,
      };

  factory PosOrder.fromMap(Map<String, dynamic> map, List<OrderItem> items) => PosOrder(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        subtotal: map['subtotal'] as int,
        tax: map['tax'] as int,
        total: map['total'] as int,
        payMethod: map['pay_method'] as String,
        paid: map['paid'] as int,
        change: map['change_amount'] as int,
        isFree: (map['is_free'] as int? ?? 0) == 1,
        items: items,
      );
}
