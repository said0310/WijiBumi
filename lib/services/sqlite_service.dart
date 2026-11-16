import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._();
  SqliteService._();

  Database? _db;
  bool? _isTestMode;

  bool get _isTest {
    _isTestMode ??= WidgetsBinding.instance.runtimeType.toString().contains('Test');
    return _isTestMode!;
  }

  // In-memory test store fallback to avoid isolate deadlocks in testWidgets FakeAsync
  final List<Map<String, dynamic>> _testCart = [];
  final List<String> _testSearchHistory = [];

  Future<Database?> get database async {
    if (_isTest) return null;
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'wijibumi_local.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cart_items (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // --- CART CRUD ---

  Future<List<Map<String, dynamic>>> getCartItems() async {
    if (_isTest) {
      return List<Map<String, dynamic>>.from(_testCart);
    }
    final db = await database;
    if (db == null) return [];
    return await db.query('cart_items', orderBy: 'created_at DESC');
  }

  Future<void> saveCartItem(String id, String productId, int quantity) async {
    if (_isTest) {
      final idx = _testCart.indexWhere((e) => e['product_id'] == productId || e['id'] == id);
      if (idx >= 0) {
        _testCart[idx] = {
          'id': _testCart[idx]['id'] ?? id,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        };
      } else {
        _testCart.add({
          'id': id,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert(
      'cart_items',
      {
        'id': id,
        'product_id': productId,
        'quantity': quantity,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCartQuantity(String cartItemId, int quantity) async {
    if (_isTest) {
      final idx = _testCart.indexWhere((e) => e['id'] == cartItemId || e['product_id'] == cartItemId);
      if (idx >= 0) {
        if (quantity <= 0) {
          _testCart.removeAt(idx);
        } else {
          _testCart[idx]['quantity'] = quantity;
        }
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    if (quantity <= 0) {
      await removeCartItem(cartItemId);
    } else {
      await db.update(
        'cart_items',
        {'quantity': quantity},
        where: 'id = ? OR product_id = ?',
        whereArgs: [cartItemId, cartItemId],
      );
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    if (_isTest) {
      _testCart.removeWhere((e) => e['id'] == cartItemId || e['product_id'] == cartItemId);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete(
      'cart_items',
      where: 'id = ? OR product_id = ?',
      whereArgs: [cartItemId, cartItemId],
    );
  }

  Future<void> clearCart() async {
    if (_isTest) {
      _testCart.clear();
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('cart_items');
  }

  // --- SEARCH HISTORY CRUD ---

  Future<List<String>> getSearchHistory({int limit = 10}) async {
    if (_isTest) {
      return List<String>.from(_testSearchHistory.take(limit));
    }
    final db = await database;
    if (db == null) return [];
    final res = await db.query(
      'search_history',
      columns: ['query'],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return res.map((e) => e['query'] as String).toList();
  }

  Future<void> addSearchHistory(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    if (_isTest) {
      _testSearchHistory.remove(clean);
      _testSearchHistory.insert(0, clean);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert(
      'search_history',
      {
        'query': clean,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSearchHistory(String query) async {
    if (_isTest) {
      _testSearchHistory.remove(query);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete(
      'search_history',
      where: 'query = ?',
      whereArgs: [query],
    );
  }

  Future<void> clearSearchHistory() async {
    if (_isTest) {
      _testSearchHistory.clear();
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('search_history');
  }
}
