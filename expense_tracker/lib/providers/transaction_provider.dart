import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> _incomeTransactions = [];
  List<Transaction> _expenseTransactions = [];
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  List<Transaction> get transactions => _transactions;
  List<Transaction> get incomeTransactions => _incomeTransactions;
  List<Transaction> get expenseTransactions => _expenseTransactions;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get balance => _totalIncome - _totalExpenses;

  // Load all transactions from the database
  Future<void> loadTransactions() async {
    _transactions = await DatabaseHelper.instance.getTransactions();
    _incomeTransactions = await DatabaseHelper.instance.getTransactionsByType(
      'income',
    );
    _expenseTransactions = await DatabaseHelper.instance.getTransactionsByType(
      'expense',
    );
    _totalIncome = await DatabaseHelper.instance.getTotalIncome();
    _totalExpenses = await DatabaseHelper.instance.getTotalExpenses();
    notifyListeners();
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    await loadTransactions();
  }

  // Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await loadTransactions();
  }

  // Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((tx) => tx.category == category).toList();
  }
}
