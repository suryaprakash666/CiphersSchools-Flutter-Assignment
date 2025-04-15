import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Add alias to avoid conflict
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'database_helper.dart'; // Import the database helper

// Ensure Firebase is only initialized once
bool _initialized = false;

Future<void> initializeFirebase() async {
  if (!_initialized) {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Initialize Firebase Auth
      FirebaseAuth.instance;
      _initialized = true;
      print("Firebase initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }
}

void main() async {
  await initializeFirebase();
  runApp(const MyApp());
}

// Use StatefulWidget for the root to better support hot reload
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Use Material 3 design
      ),
      home: const AuthenticationPage(),
    );
  }
}

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  bool _isSigningIn = false;
  bool _showDevCode = false;
  final TextEditingController _codeController = TextEditingController();
  final String _secretCode = 'cipher123'; // Secret code for dev sign-in

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _devSignIn(BuildContext context) async {
    if (_codeController.text == _secretCode) {
      setState(() {
        _isSigningIn = true;
      });

      try {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer mode activated!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Expense Tracker'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid developer code')));
    }
  }

  // Anonymous sign-in - works without verification
  Future<void> _signInAnonymously(BuildContext context) async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in anonymously')));

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Expense Tracker'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  // Google sign-in method
  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() {
            _isSigningIn = false;
          });
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;
      if (user != null) {
        // Store user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'lastLogin': DateTime.now(),
        }, SetOptions(merge: true));

        // Save user ID to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${user.displayName}!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Expense Tracker'),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Sign-in failed';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? 'Authentication error occurred';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColorLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo or App Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    const Text(
                      'Expense Tracker',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // App Subtitle
                    const Text(
                      'Manage your finances effortlessly',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 48),

                    // Sign-in Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            _isSigningIn
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _signInWithGoogle(context),
                                      // Replace Image.asset with Icon
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        size: 26,
                                        color: Colors.red,
                                      ),
                                      label: const Text('Sign in with Google'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black87,
                                        backgroundColor: Colors.white,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Secret code reveal button (long press)
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onLongPress: () {
                                        setState(() {
                                          _showDevCode = true;
                                        });
                                      },
                                      child: Container(
                                        height: 4,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        alignment: Alignment.center,
                                      ),
                                    ),

                                    // Developer code input (hidden by default)
                                    if (_showDevCode) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Developer Access',
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _codeController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter developer code',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        obscureText: true,
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () => _devSignIn(context),
                                        child: const Text('Access'),
                                      ),
                                    ],
                                  ],
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  TabController? _tabController;

  final List<String> _categories = [
    'Food',
    'Travel',
    'Entertainment',
    'Shopping',
    'Bills',
    'Subscriptions',
    'Income',
  ];

  // Controllers for form inputs
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseHelper.instance.getTransactions();
      setState(() {
        _expenses = transactions;
        _isLoading = false;
      });
    } catch (e) {
      // If the database is empty or there's an error, use sample data
      if (_expenses.isEmpty) {
        _expenses = [
          {
            'id': '1',
            'title': 'Groceries',
            'amount': 45.99,
            'date': DateTime.now().subtract(const Duration(days: 1)),
            'category': 'Food',
            'isExpense': true,
          },
          {
            'id': '2',
            'title': 'Movie Tickets',
            'amount': 30.00,
            'date': DateTime.now().subtract(const Duration(days: 2)),
            'category': 'Entertainment',
            'isExpense': true,
          },
          {
            'id': '3',
            'title': 'Salary',
            'amount': 1200.00,
            'date': DateTime.now().subtract(const Duration(days: 5)),
            'category': 'Income',
            'isExpense': false,
          },
        ];
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate total balance
  double get _totalBalance {
    double income = _expenses
        .where((expense) => !expense['isExpense'])
        .fold(0.0, (sum, expense) => sum + (expense['amount'] as double));

    double expenses = _expenses
        .where((expense) => expense['isExpense'])
        .fold(0.0, (sum, expense) => sum + (expense['amount'] as double));

    return income - expenses;
  }

  // Calculate total expense
  double get _totalExpense {
    return _expenses
        .where((expense) => expense['isExpense'])
        .fold(0.0, (sum, expense) => sum + (expense['amount'] as double));
  }

  // Calculate total income
  double get _totalIncome {
    return _expenses
        .where((expense) => !expense['isExpense'])
        .fold(0.0, (sum, expense) => sum + (expense['amount'] as double));
  }

  // Get expenses by category for the chart
  Map<String, double> get _expensesByCategory {
    final Map<String, double> categoryMap = {};

    for (var expense in _expenses.where((e) => e['isExpense'])) {
      final category = expense['category'] as String;
      final amount = expense['amount'] as double;

      if (categoryMap.containsKey(category)) {
        categoryMap[category] = (categoryMap[category] ?? 0) + amount;
      } else {
        categoryMap[category] = amount;
      }
    }

    return categoryMap;
  }

  Future<void> _addTransaction(Map<String, dynamic> transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await _loadTransactions();
  }

  Future<void> _deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await _loadTransactions();
  }

  void _addNewExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add New Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Transaction type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() => _isExpense = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  _isExpense
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isExpense ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() => _isExpense = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  !_isExpense
                                      ? Colors.green
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    !_isExpense ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount field
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField(
                    value: _selectedCategory,
                    items:
                        _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCategory = value as String;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = _titleController.text;
                        final amount =
                            double.tryParse(_amountController.text) ?? 0;

                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter valid title and amount',
                              ),
                            ),
                          );
                          return;
                        }

                        // Add the new transaction
                        final newTransaction = {
                          'id': DateTime.now().toString(),
                          'title': title,
                          'amount': amount,
                          'date': DateTime.now(),
                          'category': _selectedCategory,
                          'isExpense': _isExpense,
                        };

                        _addTransaction(newTransaction);

                        // Clear the controllers
                        _titleController.clear();
                        _amountController.clear();

                        // Close the bottom sheet
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Transaction'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AuthenticationPage(),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Stats'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Transactions Tab
                  _buildTransactionsTab(),

                  // Stats Tab
                  _buildStatsTab(),

                  // Profile Tab
                  _buildProfileTab(),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewExpense,
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Transaction',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Balance Card
              Expanded(
                flex: 2,
                child: _buildSummaryCard(
                  title: 'Balance',
                  amount: _totalBalance,
                  color: _totalBalance >= 0 ? Colors.blue : Colors.red,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 8),

              // Income Card
              Expanded(
                child: _buildSummaryCard(
                  title: 'Income',
                  amount: _totalIncome,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 8),

              // Expense Card
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expense',
                  amount: _totalExpense,
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child:
              _expenses.isEmpty
                  ? const Center(
                    child: Text(
                      'No transactions yet. Add some!',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: _expenses.length,
                    itemBuilder: (ctx, index) {
                      final expense = _expenses[index];
                      return Dismissible(
                        key: Key(expense['id']),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                    'Do you want to delete this transaction?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteTransaction(expense['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${expense['title']} deleted'),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    expense['isExpense']
                                        ? Colors.red.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                expense['isExpense'] ? Icons.remove : Icons.add,
                                color:
                                    expense['isExpense']
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                            title: Text(
                              expense['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${expense['category']} • ${_formatDate(expense['date'])}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Text(
                              '${expense['isExpense'] ? '-' : '+'}\$${expense['amount'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color:
                                    expense['isExpense']
                                        ? Colors.red
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final categoryExpenses = _expensesByCategory;
    final totalExpense = _totalExpense;

    // Generate colors for each category
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Pie Chart for category distribution
          if (categoryExpenses.isNotEmpty)
            SizedBox(
              height: 240,
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(categoryExpenses.length, (index) {
                      final category = categoryExpenses.keys.elementAt(index);
                      final amount = categoryExpenses[category] ?? 0;
                      final percentage =
                          totalExpense > 0 ? (amount / totalExpense * 100) : 0;

                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: amount,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            )
          else
            const Center(child: Text('No expense data to display')),

          const SizedBox(height: 24),

          // Legend
          if (categoryExpenses.isNotEmpty) ...[
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // List of categories with amounts and colors
            ...List.generate(categoryExpenses.length, (index) {
              final category = categoryExpenses.keys.elementAt(index);
              final amount = categoryExpenses[category] ?? 0;
              final percentage =
                  totalExpense > 0 ? (amount / totalExpense * 100) : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 32),

          // Monthly summary heading
          const Text(
            'Monthly Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Monthly summary stats
          _buildMonthlySummary(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Expense Tracker User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'User ID: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not signed in'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Sign out button
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AuthenticationPage(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    // Group expenses by month
    final Map<String, double> monthlyExpenses = {};
    final Map<String, double> monthlyIncomes = {};

    for (var transaction in _expenses) {
      final date = transaction['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = transaction['amount'] as double;

      if (transaction['isExpense']) {
        monthlyExpenses[key] = (monthlyExpenses[key] ?? 0) + amount;
      } else {
        monthlyIncomes[key] = (monthlyIncomes[key] ?? 0) + amount;
      }
    }

    // Sort keys by date
    final List<String> sortedKeys =
        <String>{
          ...monthlyExpenses.keys.cast<String>(),
          ...monthlyIncomes.keys.cast<String>(),
        }.toList();
    sortedKeys.sort((a, b) => b.compareTo(a)); // Sort in descending order

    return Column(
      children:
          sortedKeys.map((month) {
            final parts = month.split('-');
            final year = parts[0];
            final monthNum = int.parse(parts[1]);
            final monthName = _getMonthName(monthNum);

            final income = monthlyIncomes[month] ?? 0;
            final expense = monthlyExpenses[month] ?? 0;
            final balance = income - expense;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName $year',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Income'),
                              const SizedBox(height: 4),
                              Text(
                                '\$${income.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expense'),
                              const SizedBox(height: 4),
                              Text(
                                '\$${expense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Balance'),
                              const SizedBox(height: 4),
                              Text(
                                '\$${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      balance >= 0 ? Colors.blue : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tabController?.dispose();
    super.dispose();
  }
}
