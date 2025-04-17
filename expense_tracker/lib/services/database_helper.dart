import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as app;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  // Create a new transaction
  Future<int> createTransaction(app.Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  // Read all transactions
  Future<List<app.Transaction>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return Future.value(
      result.map((json) => app.Transaction.fromMap(json)).toList(),
    );
  }

  // Read transactions by type (income or expense)
  Future<List<app.Transaction>> getTransactionsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return result
        .map((json) => app.Transaction.fromMap(json))
        .toList();
  }

  // Update a transaction
  Future<int> updateTransaction(app.Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Get total income
  Future<double> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['income'],
    );
    return result.isNotEmpty ? (result.first['total'] as double? ?? 0.0) : 0.0;
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['expense'],
    );
    return result.isNotEmpty ? (result.first['total'] as double? ?? 0.0) : 0.0;
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
