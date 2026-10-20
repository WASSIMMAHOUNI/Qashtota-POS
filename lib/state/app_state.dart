import 'package:flutter/foundation.dart';
import '../models/product_recipe.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/supply.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Product> products = [];
  List<CartItem> cart = [];
  List<PosOrder> orders = [];
  List<Supply> supplies = [];
  String category = 'all';
  String search = '';
  bool loading = true;

  int get subtotal => cart.fold(0, (sum, item) => sum + item.lineTotal);
  int get tax => 0; // Set to (subtotal * 0.09).round() if you want tax enabled.
  int get total => subtotal + tax;
  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty);
  bool get hasLowStock => products.any((p) => p.stock <= 3);
  bool get hasLowSupplies => supplies.any((s) => s.quantity <= s.minQuantity);
  int get freeOrdersValue => orders.where((o) => o.isFree).fold(0, (sum, order) => sum + order.subtotal);

  List<String> get categories => const ['all', 'قشطوطة', 'مولوخينو', 'كريب', 'كيك بوم', 'كشري', 'إضافات'];

  List<Product> get visibleProducts {
    return products.where((p) {
      final categoryOk = category == 'all' || p.category == category;
      final searchOk = search.trim().isEmpty || p.name.contains(search.trim()) || p.category.contains(search.trim());
      return categoryOk && searchOk;
    }).toList();
  }

  Future<void> init() async {
    loading = true;
    notifyListeners();
    products = await _db.getProducts();
    orders = await _db.getOrders();
    supplies = await _db.getAllSupplies();
    loading = false;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  String? addToCart(Product product) {
    if (product.stock <= 0) return 'المنتج غير متوفر';
    CartItem? existing;
    for (final item in cart) {
      if (item.product.id == product.id) {
        existing = item;
        break;
      }
    }
    if (existing == null) {
      cart.add(CartItem(product: product));
    } else {
      if (existing.qty >= product.stock) return 'لا يوجد مخزون كاف';
      existing.qty++;
    }
    notifyListeners();
    return null;
  }

  void removeFromCart(Product product) {
    cart.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  String? changeQty(Product product, int delta) {
    CartItem? item;
    for (final cartItem in cart) {
      if (cartItem.product.id == product.id) {
        item = cartItem;
        break;
      }
    }
    if (item == null) return null;
    final nextQty = item.qty + delta;
    if (nextQty <= 0) {
      cart.remove(item);
    } else if (nextQty > product.stock) {
      return 'الحد الأقصى للمخزون';
    } else {
      item.qty = nextQty;
    }
    notifyListeners();
    return null;
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  void cancelLast() {
    if (cart.isEmpty) return;
    final last = cart.last;
    if (last.qty > 1) {
      last.qty--;
    } else {
      cart.removeLast();
    }
    notifyListeners();
  }

  Future<void> saveProduct(Product product) async {
    await _db.upsertProduct(product);
    products = await _db.getProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    products = await _db.getProducts();
    notifyListeners();
  }

  Future<void> deleteOrder(int id) async {
    await _db.deleteOrder(id);
    products = await _db.getProducts();
    orders = await _db.getOrders();
    supplies = await _db.getAllSupplies();
    notifyListeners();
  }

  Future<void> clearAllOrders() async {
    await _db.clearAllOrders();
    products = await _db.getProducts();
    orders = await _db.getOrders();
    supplies = await _db.getAllSupplies();
    notifyListeners();
  }

  Future<void> exportDatabase(String targetPath) async {
    await _db.exportDatabase(targetPath);
  }

  Future<void> restoreDatabase(String sourcePath) async {
    await _db.restoreDatabase(sourcePath);
    await init();
  }

  Future<List<RecipeSupplyLine>> getRecipe(int productId) async {
    return _db.getRecipe(productId);
  }

  Future<void> saveRecipe(int productId, List<RecipeInputItem> items) async {
    await _db.addRecipe(productId, items);
    notifyListeners();
  }

  Future<void> deleteRecipe(int productId) async {
    await _db.deleteRecipe(productId);
    notifyListeners();
  }

  Future<void> saveSupply(Supply supply) async {
    if (supply.id == null) {
      await _db.insertSupply(supply);
    } else {
      await _db.updateSupply(supply);
    }
    supplies = await _db.getAllSupplies();
    notifyListeners();
  }

  Future<void> deleteSupply(int id) async {
    await _db.deleteSupply(id);
    supplies = await _db.getAllSupplies();
    notifyListeners();
  }

  Future<List<Supply>> getLowSupplies() async {
    return _db.getLowSupplies();
  }

  double estimateItemCost(CartItem item, List<RecipeSupplyLine> recipe) {
    var totalCost = 0.0;
    for (final line in recipe) {
      totalCost += line.amount * item.qty * line.supplyCost;
    }
    return totalCost;
  }

  Future<PosOrder> checkout({required int paid, String payMethod = 'cash'}) async {
    if (cart.isEmpty) throw Exception('Cart is empty');
    final isFree = payMethod == 'free';
    final finalTotal = isFree ? 0 : total;
    final finalPaid = isFree ? 0 : paid;
    final finalChange = isFree ? 0 : paid - total;
    if (!isFree && paid < total) throw Exception('Insufficient paid amount');
    final now = DateTime.now();
    final order = PosOrder(
      createdAt: now,
      subtotal: subtotal,
      tax: tax,
      total: finalTotal,
      payMethod: payMethod,
      paid: finalPaid,
      change: finalChange,
      isFree: isFree,
      items: cart.map((item) => OrderItem(orderId: 0, productId: item.product.id!, name: item.product.name, emoji: item.product.emoji, imagePath: item.product.imagePath, price: item.product.price, qty: item.qty)).toList(),
    );
    final id = await _db.createOrder(order);
    cart.clear();
    products = await _db.getProducts();
    orders = await _db.getOrders();
    supplies = await _db.getAllSupplies();
    notifyListeners();
    return orders.firstWhere(
      (o) => o.id == id,
      orElse: () => PosOrder(
        id: id,
        createdAt: now,
        subtotal: order.subtotal,
        tax: order.tax,
        total: order.total,
        payMethod: order.payMethod,
        paid: order.paid,
        change: order.change,
        isFree: order.isFree,
        items: order.items,
      ),
    );
  }
}
