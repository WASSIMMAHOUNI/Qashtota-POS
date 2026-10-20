import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product_recipe.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/supply.dart';


class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<String> get databasePath async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return p.join(await databaseFactory.getDatabasesPath(), 'qashtota_pos.db');
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = p.join(await databaseFactory.getDatabasesPath(), 'qashtota_pos.db');
    _db = await databaseFactory.openDatabase(path, options: OpenDatabaseOptions(version: 8, onCreate: _onCreate, onUpgrade: _onUpgrade));
    await seedProductsIfEmpty();
    await _applyDefaultEmojisToExistingProducts(_db!);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        emoji TEXT NOT NULL,
        image_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        subtotal INTEGER NOT NULL,
        tax INTEGER NOT NULL,
        total INTEGER NOT NULL,
        pay_method TEXT NOT NULL,
        paid INTEGER NOT NULL,
        change_amount INTEGER NOT NULL,
        is_free INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        image_path TEXT,
        price INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE supplies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        min_quantity REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE product_recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        supply_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id),
        FOREIGN KEY(supply_id) REFERENCES supplies(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE order_item_supplies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_item_id INTEGER NOT NULL,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        supply_id INTEGER NOT NULL,
        qty REAL NOT NULL,
        FOREIGN KEY(order_item_id) REFERENCES order_items(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'products', 'image_path', 'TEXT');
      await _addColumnIfMissing(db, 'order_items', 'image_path', 'TEXT');
    }
    if (oldVersion < 3) {
      await _createSuppliesTableIfMissing(db);
      await _createProductRecipesTableIfMissing(db);
      await _addColumnIfMissing(db, 'orders', 'is_free', 'INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(db, 'supplies', 'cost', 'REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 6) {
      await _createOrderItemSuppliesTableIfMissing(db);
    }
    if (oldVersion < 5) {
      await replaceDefaultProducts(db);
    }
    if (oldVersion < 7) {
      await _applyDefaultEmojisToExistingProducts(db);
    }
    if (oldVersion < 8) {
      await _migrateMenuToV8(db);
      await _applyDefaultEmojisToExistingProducts(db);
    }
    await _createSuppliesTableIfMissing(db);
    await _createProductRecipesTableIfMissing(db);
    await _createOrderItemSuppliesTableIfMissing(db);
    await _addColumnIfMissing(db, 'orders', 'is_free', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'supplies', 'cost', 'REAL NOT NULL DEFAULT 0');
  }

  Future<void> _createSuppliesTableIfMissing(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        min_quantity REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createProductRecipesTableIfMissing(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        supply_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id),
        FOREIGN KEY(supply_id) REFERENCES supplies(id)
      )
    ''');
  }

  Future<void> _createOrderItemSuppliesTableIfMissing(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_item_supplies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_item_id INTEGER NOT NULL,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        supply_id INTEGER NOT NULL,
        qty REAL NOT NULL,
        FOREIGN KEY(order_item_id) REFERENCES order_items(id)
      )
    ''');
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> seedProductsIfEmpty() async {
    final database = _db ?? await db;

    final result = await database.rawQuery('SELECT COUNT(*) AS count FROM products');
    final count = result.first['count'] as int? ?? 0;

    if (count > 0) return;
    await _insertDefaultProducts(database);
  }

  Future<void> replaceDefaultProducts(DatabaseExecutor database) async {
    await database.delete('order_item_supplies');
    await database.delete('product_recipes');
    await database.delete('order_items');
    await database.delete('orders');
    await database.delete('products');
    await _insertDefaultProducts(database);
  }

  Future<void> _insertDefaultProducts(DatabaseExecutor database) async {
    const seed = <Product>[
      Product(name: 'سادة', category: 'قشطوطة', price: 250, stock: 100, emoji: ''),
      Product(name: 'كراميل', category: 'قشطوطة', price: 400, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة', category: 'قشطوطة', price: 400, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'قشطوطة', price: 500, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'قشطوطة', price: 550, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'قشطوطة', price: 500, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'قشطوطة', price: 550, stock: 100, emoji: ''),
      Product(name: 'موز شوكولاطة', category: 'قشطوطة', price: 550, stock: 100, emoji: ''),
      Product(name: 'فراولة شوكولاطة', category: 'قشطوطة', price: 550, stock: 100, emoji: ''),
      Product(name: 'مانغا', category: 'قشطوطة', price: 700, stock: 100, emoji: ''),
      Product(name: 'كيوي', category: 'قشطوطة', price: 600, stock: 100, emoji: ''),
      Product(name: 'فواكه مشكلة', category: 'قشطوطة', price: 700, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة', category: 'مولوخينو', price: 550, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'مولوخينو', price: 600, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'مولوخينو', price: 600, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'مولوخينو', price: 650, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'مولوخينو', price: 650, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة', category: 'كريب', price: 500, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'كريب', price: 600, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'كريب', price: 550, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'كريب', price: 600, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'كريب', price: 600, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة', category: 'كيك بوم', price: 500, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'كيك بوم', price: 550, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'كيك بوم', price: 600, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'كيك بوم', price: 650, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'كيك بوم', price: 650, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة', category: 'كشري', price: 500, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'كشري', price: 600, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'كشري', price: 550, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'كشري', price: 600, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'كشري', price: 600, stock: 100, emoji: ''),
      Product(name: 'موز', category: 'إضافات', price: 200, stock: 100, emoji: ''),
      Product(name: 'فراولة', category: 'إضافات', price: 250, stock: 100, emoji: ''),
      Product(name: 'مانغا', category: 'إضافات', price: 350, stock: 100, emoji: ''),
      Product(name: 'كيوي', category: 'إضافات', price: 350, stock: 100, emoji: ''),
      Product(name: 'فواكه مشكلة', category: 'إضافات', price: 350, stock: 100, emoji: ''),
    ];
    final batch = database.batch();
    for (final product in seed) {
      batch.insert('products', product.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
    await _applyDefaultEmojisToExistingProducts(database);
  }

  Future<void> _migrateMenuToV8(DatabaseExecutor database) async {
    await database.rawUpdate(
      'UPDATE products SET category = ? WHERE category = ?',
      ['كيك بوم', 'كلاب بوم'],
    );

    const keshriProducts = <Product>[
      Product(name: 'شوكولاطة', category: 'كشري', price: 500, stock: 100, emoji: ''),
      Product(name: 'شوكولاطة بيضاء و مكسرات', category: 'كشري', price: 600, stock: 100, emoji: ''),
      Product(name: 'لوتس', category: 'كشري', price: 550, stock: 100, emoji: ''),
      Product(name: 'بيستاشيو', category: 'كشري', price: 600, stock: 100, emoji: ''),
      Product(name: 'خربطة', category: 'كشري', price: 600, stock: 100, emoji: ''),
    ];

    for (final product in keshriProducts) {
      final existing = await database.query(
        'products',
        columns: ['id'],
        where: 'name = ? AND category = ?',
        whereArgs: [product.name, product.category],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;
      await database.insert('products', product.toMap()..remove('id'));
    }
  }

  Future<void> _applyDefaultEmojisToExistingProducts(DatabaseExecutor database) async {
    final rows = await database.query('products', columns: ['id', 'name', 'category', 'emoji']);
    final batch = database.batch();
    for (final row in rows) {
      final id = row['id'] as int?;
      final name = (row['name'] as String?)?.trim() ?? '';
      final category = (row['category'] as String?)?.trim() ?? '';
      final currentEmoji = (row['emoji'] as String?)?.trim() ?? '';
      if (id == null || name.isEmpty || category.isEmpty || currentEmoji.isNotEmpty) continue;
      final emoji = _defaultEmojiFor(category, name);
      if (emoji == null || emoji.isEmpty) continue;
      batch.update('products', {'emoji': emoji}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  String? _defaultEmojiFor(String category, String name) {
    const byName = <String, String>{
      'سادة': '🥛',
      'كراميل': '🍯',
      'شوكولاطة': '🍫',
      'لوتس': '🍪',
      'بيستاشيو': '🌰',
      'شوكولاطة بيضاء و مكسرات': '🍬',
      'خربطة': '🎉',
      'موز شوكولاطة': '🍌',
      'فراولة شوكولاطة': '🍓',
      'موز': '🍌',
      'فراولة': '🍓',
      'مانغا': '🥭',
      'كيوي': '🥝',
      'فواكه مشكلة': '🍇',
    };

    final exact = byName[name];
    if (exact != null) return exact;

    switch (category) {
      case 'قشطوطة':
        return '🍨';
      case 'مولوخينو':
        return '🥤';
      case 'كريب':
        return '🥞';
      case 'كيك بوم':
        return '🧇';
      case 'كشري':
        return '🍮';
      case 'إضافات':
        return '➕';
      default:
        return '🍽️';
    }
  }
  Future<List<Product>> getProducts() async {
    final rows = await (await db).query('products', orderBy: 'id DESC');
    return rows.map(Product.fromMap).toList();
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> upsertProduct(Product product) async {
    final database = await db;
    if (product.id == null) {
      await database.insert('products', product.toMap()..remove('id'));
    } else {
      await database.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    }
  }

  Future<void> deleteProduct(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('product_recipes', where: 'product_id = ?', whereArgs: [id]);
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Supply>> getAllSupplies() async {
    final rows = await (await db).query('supplies', orderBy: 'name ASC');
    return rows.map(Supply.fromMap).toList();
  }

  Future<List<Supply>> getLowSupplies() async {
    final rows = await (await db).rawQuery('SELECT * FROM supplies WHERE quantity <= min_quantity ORDER BY name ASC');
    return rows.map(Supply.fromMap).toList();
  }

  Future<int> insertSupply(Supply supply) async {
    return (await db).insert('supplies', supply.toMap()..remove('id'));
  }

  Future<void> updateSupply(Supply supply) async {
    if (supply.id == null) return;
    await (await db).update('supplies', supply.toMap(), where: 'id = ?', whereArgs: [supply.id]);
  }

  Future<void> deleteSupply(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('product_recipes', where: 'supply_id = ?', whereArgs: [id]);
      await txn.delete('supplies', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addRecipe(int productId, List<RecipeInputItem> items) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('product_recipes', where: 'product_id = ?', whereArgs: [productId]);
      for (final item in items) {
        if (item.amount <= 0) continue;
        await txn.insert('product_recipes', {
          'product_id': productId,
          'supply_id': item.supplyId,
          'amount': item.amount,
        });
      }
    });
  }

  Future<List<RecipeSupplyLine>> getRecipe(int productId) async {
    final rows = await (await db).rawQuery('''
      SELECT pr.id, pr.product_id, pr.supply_id, pr.amount, s.name AS supply_name, s.unit, s.quantity, s.cost
      FROM product_recipes pr
      INNER JOIN supplies s ON s.id = pr.supply_id
      WHERE pr.product_id = ?
      ORDER BY s.name ASC
    ''', [productId]);
    return rows.map((row) {
      return RecipeSupplyLine(
        supplyId: row['supply_id'] as int,
        supplyName: row['supply_name'] as String,
        unit: row['unit'] as String,
        amount: _toDouble(row['amount']),
        availableQuantity: _toDouble(row['quantity']),
        supplyCost: _toDouble(row['cost']),
      );
    }).toList();
  }

  Future<void> deleteRecipe(int productId) async {
    await (await db).delete('product_recipes', where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<int> createOrder(PosOrder order) async {
    final database = await db;
    return database.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap()..remove('id'));
      for (final item in order.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['order_id'] = orderId;
        final orderItemId = await txn.insert('order_items', itemMap);
        await txn.rawUpdate('UPDATE products SET stock = MAX(stock - ?, 0) WHERE id = ?', [item.qty, item.productId]);
        final recipeRows = await txn.query('product_recipes', where: 'product_id = ?', whereArgs: [item.productId]);
        for (final recipeRow in recipeRows) {
          final supplyId = recipeRow['supply_id'] as int;
          final amount = _toDouble(recipeRow['amount']);
          final consumed = amount * item.qty;
          await txn.rawUpdate('UPDATE supplies SET quantity = MAX(quantity - ?, 0) WHERE id = ?', [consumed, supplyId]);
          await txn.insert('order_item_supplies', {
            'order_item_id': orderItemId,
            'order_id': orderId,
            'product_id': item.productId,
            'supply_id': supplyId,
            'qty': consumed,
          });
        }
      }
      return orderId;
    });
  }

  Future<void> deleteOrder(int orderId) async {
    final database = await db;
    await database.transaction((txn) async {
      final itemRows = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      for (final row in itemRows) {
        final productId = row['product_id'] as int;
        final qty = row['qty'] as int;
        await txn.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [qty, productId]);
      }
      await _restoreSuppliesForOrder(txn, orderId, itemRows);
      await txn.delete('order_item_supplies', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<void> clearAllOrders() async {
    final database = await db;
    await database.transaction((txn) async {
      final orderRows = await txn.query('orders', columns: ['id']);
      final itemRows = await txn.query('order_items');
      for (final row in itemRows) {
        final productId = row['product_id'] as int;
        final qty = row['qty'] as int;
        await txn.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [qty, productId]);
      }
      for (final orderRow in orderRows) {
        final orderId = orderRow['id'] as int;
        final orderItems = itemRows.where((row) => row['order_id'] == orderId).toList();
        await _restoreSuppliesForOrder(txn, orderId, orderItems);
      }
      await txn.delete('order_item_supplies');
      await txn.delete('order_items');
      await txn.delete('orders');
    });
  }

  Future<void> _restoreSuppliesForOrder(
    Transaction txn,
    int orderId,
    List<Map<String, Object?>> itemRows,
  ) async {
    final snapshotRows = await txn.query('order_item_supplies', where: 'order_id = ?', whereArgs: [orderId]);
    if (snapshotRows.isNotEmpty) {
      final totalsBySupplyId = <int, double>{};
      for (final row in snapshotRows) {
        final supplyId = row['supply_id'] as int;
        final qty = _toDouble(row['qty']);
        totalsBySupplyId[supplyId] = (totalsBySupplyId[supplyId] ?? 0) + qty;
      }
      for (final entry in totalsBySupplyId.entries) {
        await txn.rawUpdate('UPDATE supplies SET quantity = quantity + ? WHERE id = ?', [entry.value, entry.key]);
      }
      return;
    }

    // Backward compatibility for orders created before migration to version 6.
    for (final row in itemRows) {
      final productId = row['product_id'] as int;
      final qty = row['qty'] as int;
      final recipeRows = await txn.query('product_recipes', where: 'product_id = ?', whereArgs: [productId]);
      for (final recipeRow in recipeRows) {
        final supplyId = recipeRow['supply_id'] as int;
        final amount = _toDouble(recipeRow['amount']);
        final restored = amount * qty;
        await txn.rawUpdate('UPDATE supplies SET quantity = quantity + ? WHERE id = ?', [restored, supplyId]);
      }
    }
  }

  Future<List<PosOrder>> getOrders() async {
    final database = await db;
    final orderRows = await database.query('orders', orderBy: 'created_at DESC');
    final result = <PosOrder>[];
    for (final row in orderRows) {
      final itemRows = await database.query('order_items', where: 'order_id = ?', whereArgs: [row['id']]);
      result.add(PosOrder.fromMap(row, itemRows.map(OrderItem.fromMap).toList()));
    }
    return result;
  }

  Future<void> exportDatabase(String targetPath) async {
    final sourcePath = await databasePath;
    final source = File(sourcePath);
    if (!await source.exists()) {
      await db;
    }
    await File(sourcePath).copy(targetPath);
  }

  Future<void> restoreDatabase(String sourcePath) async {
    final targetPath = await databasePath;
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('Backup file not found');
    }
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final target = File(targetPath);
    if (await target.exists()) {
      await target.delete();
    }
    await source.copy(targetPath);
    await db;
  }
}

