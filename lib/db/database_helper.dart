import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../models/expense.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // For web platform: keep data in memory
  static final Map<String, List<Map<String, dynamic>>> _webDb = {
    'categories': [],
    'expenses': [],
  };
  static int _categoryIdCounter = 1;
  static int _expenseIdCounter = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (kIsWeb) {
      // Initialize in-memory database for web
      _initWebDb();
      // Return a fake database which won't be used
      // The actual operations will check kIsWeb and use _webDb
      return Future.value(null as Database);
    } else {
      _database = await _initDB('expenses.db');
      return _database!;
    }
  }

  void _initWebDb() {
    // Initialize with default categories if empty
    if (_webDb['categories']!.isEmpty) {
      _webDb['categories']!.addAll([
        {'id': 1, 'name': 'Food', 'color': 0xFF4CAF50, 'icon': 0xe25a},
        {'id': 2, 'name': 'Transport', 'color': 0xFF2196F3, 'icon': 0xe1d5},
        {'id': 3, 'name': 'Entertainment', 'color': 0xFFF44336, 'icon': 0xe333},
        {'id': 4, 'name': 'Shopping', 'color': 0xFF9C27B0, 'icon': 0xe59c},
        {'id': 5, 'name': 'Bills', 'color': 0xFFFF9800, 'icon': 0xe19f},
        {'id': 6, 'name': 'Other', 'color': 0xFF607D8B, 'icon': 0xe3c8},
      ]);
      _categoryIdCounter = 7; // Next ID after default categories
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        color $integerType,
        icon $integerType
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        title $textType,
        amount $realType,
        date $textType,
        categoryId $integerType,
        note TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await db.insert('categories', 
      {'name': 'Food', 'color': 0xFF4CAF50, 'icon': 0xe25a}); // Food icon
    await db.insert('categories', 
      {'name': 'Transport', 'color': 0xFF2196F3, 'icon': 0xe1d5}); // Transport icon
    await db.insert('categories', 
      {'name': 'Entertainment', 'color': 0xFFF44336, 'icon': 0xe333}); // Entertainment icon
    await db.insert('categories', 
      {'name': 'Shopping', 'color': 0xFF9C27B0, 'icon': 0xe59c}); // Shopping icon
    await db.insert('categories', 
      {'name': 'Bills', 'color': 0xFFFF9800, 'icon': 0xe19f}); // Bill icon
    await db.insert('categories', 
      {'name': 'Other', 'color': 0xFF607D8B, 'icon': 0xe3c8}); // Other icon
  }

  // Category operations
  Future<List<ExpenseCategory>> getCategories() async {
    if (kIsWeb) {
      return _webDb['categories']!.map((json) => ExpenseCategory.fromJson(json)).toList();
    }
    
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => ExpenseCategory.fromJson(json)).toList();
  }

  Future<ExpenseCategory> getCategoryById(int id) async {
    if (kIsWeb) {
      final category = _webDb['categories']!.firstWhere(
        (cat) => cat['id'] == id,
        orElse: () => _webDb['categories']!.firstWhere((cat) => cat['name'] == 'Other'),
      );
      return ExpenseCategory.fromJson(category);
    }
    
    final db = await instance.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExpenseCategory.fromJson(maps.first);
    } else {
      throw Exception('Category ID $id not found');
    }
  }

  Future<int> insertCategory(ExpenseCategory category) async {
    if (kIsWeb) {
      final categoryMap = category.toJson();
      categoryMap['id'] = _categoryIdCounter++;
      _webDb['categories']!.add(categoryMap);
      return categoryMap['id'] as int;
    }
    
    final db = await instance.database;
    return await db.insert('categories', category.toJson());
  }

  Future<int> updateCategory(ExpenseCategory category) async {
    if (kIsWeb) {
      final index = _webDb['categories']!.indexWhere((cat) => cat['id'] == category.id);
      if (index != -1) {
        _webDb['categories']![index] = category.toJson();
        return 1;
      }
      return 0;
    }
    
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    if (kIsWeb) {
      final initialLength = _webDb['categories']!.length;
      _webDb['categories']!.removeWhere((cat) => cat['id'] == id);
      // Remove related expenses
      _webDb['expenses']!.removeWhere((exp) => exp['categoryId'] == id);
      return initialLength - _webDb['categories']!.length;
    }
    
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense operations
  Future<List<Expense>> getExpenses() async {
    if (kIsWeb) {
      return _webDb['expenses']!.map((json) => Expense.fromJson(json)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromJson(json)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    if (kIsWeb) {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      
      return _webDb['expenses']!
        .where((exp) {
          final date = exp['date'] as String;
          return date.compareTo(startStr) >= 0 && date.compareTo(endStr) <= 0;
        })
        .map((json) => Expense.fromJson(json))
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    
    final db = await instance.database;
    final startDate = start.toIso8601String().substring(0, 10);
    final endDate = end.toIso8601String().substring(0, 10);
    
    final result = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    
    return result.map((json) => Expense.fromJson(json)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      final expenseMap = expense.toJson();
      expenseMap['id'] = _expenseIdCounter++;
      _webDb['expenses']!.add(expenseMap);
      return expenseMap['id'] as int;
    }
    
    final db = await instance.database;
    return await db.insert('expenses', expense.toJson());
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final index = _webDb['expenses']!.indexWhere((exp) => exp['id'] == expense.id);
      if (index != -1) {
        _webDb['expenses']![index] = expense.toJson();
        return 1;
      }
      return 0;
    }
    
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toJson(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      final initialLength = _webDb['expenses']!.length;
      _webDb['expenses']!.removeWhere((exp) => exp['id'] == id);
      return initialLength - _webDb['expenses']!.length;
    }
    
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Analytics queries
  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end) async {
    if (kIsWeb) {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      
      final Map<int, double> categoryTotals = {};
      
      // Filter expenses in date range
      for (var exp in _webDb['expenses']!) {
        final date = exp['date'] as String;
        if (date.compareTo(startStr) >= 0 && date.compareTo(endStr) <= 0) {
          final categoryId = exp['categoryId'] as int;
          final amount = exp['amount'] as double;
          categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
        }
      }
      
      // Convert category IDs to names
      final Map<String, double> result = {};
      for (var entry in categoryTotals.entries) {
        final category = _webDb['categories']!.firstWhere(
          (cat) => cat['id'] == entry.key,
          orElse: () => {'name': 'Unknown'},
        );
        result[category['name'] as String] = entry.value;
      }
      
      return result;
    }
    
    final db = await instance.database;
    final startDate = start.toIso8601String().substring(0, 10);
    final endDate = end.toIso8601String().substring(0, 10);
    
    final result = await db.rawQuery('''
      SELECT c.name, SUM(e.amount) as total
      FROM expenses e
      JOIN categories c ON e.categoryId = c.id
      WHERE e.date BETWEEN ? AND ?
      GROUP BY e.categoryId
    ''', [startDate, endDate]);
    
    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['name'] as String] = (row['total'] as num).toDouble();
    }
    
    return categoryTotals;
  }

  Future<Map<String, double>> getMonthlyTotals(int year) async {
    if (kIsWeb) {
      final yearStr = year.toString();
      final Map<String, double> monthlyTotals = {};
      
      // Initialize all months with zero
      for (int i = 1; i <= 12; i++) {
        final monthStr = i.toString().padLeft(2, '0');
        monthlyTotals[monthStr] = 0;
      }
      
      // Sum expenses by month
      for (var exp in _webDb['expenses']!) {
        final date = exp['date'] as String;
        if (date.startsWith(yearStr)) {
          final month = date.substring(5, 7); // Extract month from 'YYYY-MM-DD'
          final amount = exp['amount'] as double;
          monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
        }
      }
      
      return monthlyTotals;
    }
    
    final db = await instance.database;
    
    final result = await db.rawQuery('''
      SELECT strftime('%m', date) as month, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y', date) = ?
      GROUP BY strftime('%m', date)
    ''', [year.toString()]);
    
    Map<String, double> monthlyTotals = {};
    for (var row in result) {
      monthlyTotals[row['month'] as String] = (row['total'] as num).toDouble();
    }
    
    return monthlyTotals;
  }

  Future close() async {
    if (!kIsWeb) {
      final db = await instance.database;
      db.close();
    }
  }
} 