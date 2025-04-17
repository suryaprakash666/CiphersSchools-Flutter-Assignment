import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as app;
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<app.Transaction> _transactions = [];
  List<app.Transaction> _incomeTransactions = [];
  List<app.Transaction> _expenseTransactions = [];
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  List<app.Transaction> get transactions => _transactions;
  List<app.Transaction> get incomeTransactions => _incomeTransactions;
  List<app.Transaction> get expenseTransactions => _expenseTransactions;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get balance => _totalIncome - _totalExpenses;

  // Load all transactions from the database
  Future<void> loadTransactions() async {
    _transactions =
        (await DatabaseHelper.instance.getTransactions())
            .cast<app.Transaction>();
    _incomeTransactions =
        (await DatabaseHelper.instance.getTransactionsByType(
          'income',
        )).cast<app.Transaction>();
    _expenseTransactions =
        (await DatabaseHelper.instance.getTransactionsByType(
          'expense',
        )).cast<app.Transaction>();
    _totalIncome = await DatabaseHelper.instance.getTotalIncome();
    _totalExpenses = await DatabaseHelper.instance.getTotalExpenses();
    notifyListeners();
  }

  // Add a new transaction
  Future<void> addTransaction(app.Transaction transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    await loadTransactions();
  }

  // Update an existing transaction
  Future<void> updateTransaction(app.Transaction transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await loadTransactions();
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  // Get transactions by category
  List<app.Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((tx) => tx.category == category).toList();
  }
}
