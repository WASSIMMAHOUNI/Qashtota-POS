class ProductRecipe {
  final int? id;
  final int productId;
  final int supplyId;
  final double amount;

  const ProductRecipe({
    this.id,
    required this.productId,
    required this.supplyId,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'supply_id': supplyId,
        'amount': amount,
      };

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory ProductRecipe.fromMap(Map<String, dynamic> map) => ProductRecipe(
        id: map['id'] as int?,
        productId: map['product_id'] as int,
        supplyId: map['supply_id'] as int,
        amount: _asDouble(map['amount']),
      );
}

class RecipeInputItem {
  final int supplyId;
  final double amount;

  const RecipeInputItem({required this.supplyId, required this.amount});
}

class RecipeSupplyLine {
  final int supplyId;
  final String supplyName;
  final String unit;
  final double amount;
  final double availableQuantity;
  final double supplyCost;

  const RecipeSupplyLine({
    required this.supplyId,
    required this.supplyName,
    required this.unit,
    required this.amount,
    required this.availableQuantity,
    required this.supplyCost,
  });
}
