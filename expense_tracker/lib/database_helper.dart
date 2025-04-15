import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_lib;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = path_lib.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE transactions(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      category TEXT NOT NULL,
      isExpense INTEGER NOT NULL
    )
    ''');
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', {
      'id': transaction['id'],
      'title': transaction['title'],
      'amount': transaction['amount'],
      'date': transaction['date'].toIso8601String(),
      'category': transaction['category'],
      'isExpense': transaction['isExpense'] ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result
        .map(
          (e) => {
            'id': e['id'] as String,
            'title': e['title'] as String,
            'amount': e['amount'] as double,
            'date': DateTime.parse(e['date'] as String),
            'category': e['category'] as String,
            'isExpense': e['isExpense'] == 1,
          },
        )
        .toList();
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
