import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_categories.dart';
import '../../models/transaction_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ocr_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported for native sqflite.');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        receiptImagePath TEXT,
        note TEXT,
        rawOcrText TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Insert rich sample transactions so the user immediately sees charts and reports
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now();
    final sampleData = [
      TransactionModel(
        title: 'WinMart+ Mua sắm tạp hoá',
        amount: 185000,
        date: now.subtract(const Duration(hours: 4)),
        category: ExpenseCategory.food,
        note: 'Mua sữa chua, bánh mì và trái cây',
      ),
      TransactionModel(
        title: 'Highlands Coffee',
        amount: 75000,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        category: ExpenseCategory.food,
        note: 'Cà phê phin sữa đá & bánh ngọt',
      ),
      TransactionModel(
        title: 'Nhà sách Fahasa',
        amount: 245000,
        date: now.subtract(const Duration(days: 2)),
        category: ExpenseCategory.study,
        note: 'Giáo trình Flutter & sổ tay ghi chú',
      ),
      TransactionModel(
        title: 'GrabBike di chuyển trường ĐH',
        amount: 45000,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.travel,
        note: 'Chuyến đi từ ký túc xá sang campus',
      ),
      TransactionModel(
        title: 'Chuột Logitech & Lót chuột',
        amount: 320000,
        date: now.subtract(const Duration(days: 4)),
        category: ExpenseCategory.gear,
        note: 'Mua tại GearVN phục vụ lập trình',
      ),
      TransactionModel(
        title: 'Vé xem phim CGV Cinemas',
        amount: 150000,
        date: now.subtract(const Duration(days: 5)),
        category: ExpenseCategory.entertainment,
        note: 'Vé xem phim cuối tuần cùng bạn',
      ),
      TransactionModel(
        title: 'Circle K Đồ ăn nhẹ',
        amount: 52000,
        date: now.subtract(const Duration(days: 6)),
        category: ExpenseCategory.food,
        note: 'Mì ly và nước tăng lực',
      ),
    ];

    for (final tx in sampleData) {
      await db.insert('transactions', tx.toMap());
    }
  }

  // CRUD Operations
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getAllTransactions({
    String? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(categoryFilter);
    }

    if (startDate != null && endDate != null) {
      final dateFilter = 'date >= ? AND date <= ?';
      whereClause = whereClause != null ? '$whereClause AND $dateFilter' : dateFilter;
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Get total expense amount
  Future<double> getTotalExpense() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Category distribution for Donut Chart
  Future<Map<ExpenseCategory, double>> getCategoryExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      GROUP BY category
    ''');

    Map<ExpenseCategory, double> map = {
      for (var cat in ExpenseCategory.values) cat: 0.0,
    };

    for (var row in result) {
      final catStr = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (catStr != null) {
        final cat = ExpenseCategoryExtension.fromString(catStr);
        map[cat] = (map[cat] ?? 0.0) + total;
      }
    }
    return map;
  }

  // Last 7 days spending for Bar Chart
  Future<List<Map<String, dynamic>>> getLast7DaysExpenses() async {
    final db = await instance.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final result = await db.rawQuery(
      '''
      SELECT date, amount FROM transactions
      WHERE date >= ?
      ORDER BY date ASC
      ''',
      [sevenDaysAgo.toIso8601String()],
    );

    // Build 7-day buckets
    Map<String, double> dayMap = {};
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      dayMap[key] = 0.0;
    }

    for (var row in result) {
      final dateStr = row['date'] as String;
      final dt = DateTime.parse(dateStr);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (dayMap.containsKey(key)) {
        dayMap[key] = (dayMap[key] ?? 0.0) + ((row['amount'] as num?)?.toDouble() ?? 0.0);
      }
    }

    return dayMap.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return {
        'date': date,
        'amount': entry.value,
      };
    }).toList();
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('transactions');
  }
}

