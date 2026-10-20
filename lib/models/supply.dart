class Supply {
  final int? id;
  final String name;
  final String unit;
  final double quantity;
  final double minQuantity;
  final double cost;

  const Supply({
    this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.minQuantity = 0,
    this.cost = 0,
  });

  Supply copyWith({
    int? id,
    String? name,
    String? unit,
    double? quantity,
    double? minQuantity,
    double? cost,
  }) {
    return Supply(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'cost': cost,
      };

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory Supply.fromMap(Map<String, dynamic> map) => Supply(
        id: map['id'] as int?,
        name: map['name'] as String,
        unit: map['unit'] as String,
        quantity: _asDouble(map['quantity']),
        minQuantity: _asDouble(map['min_quantity']),
        cost: _asDouble(map['cost']),
      );
}
