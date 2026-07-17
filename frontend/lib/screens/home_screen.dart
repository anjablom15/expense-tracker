import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../screens/add_expense_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expenses = await _apiService.getExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load expenses';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddExpenseScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result == true) {
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Manage Budgets',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      // Built-in Flutter property
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_expenses.isEmpty) {
      return const Center(child: Text('No expenses yet. Add you first one!'));
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.builder(
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return ListTile(
            title: Text(
              expense.description.isNotEmpty
                  ? expense.description
                  : expense.categoryName,
            ),
            subtitle: Text('${expense.categoryName} [${expense.date}]'),
            trailing: Text(
              'R${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
