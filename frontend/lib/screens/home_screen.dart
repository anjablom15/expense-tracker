import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../screens/add_expense_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();

  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
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
      print('about to get expenses');
      final expenses = await _apiService.getExpenses();
      print('got expenses: ${expenses.length}');

      print('about to get budgets');
      final budgets = await _apiService.getBudgets();
      print('got budgets: ${budgets.length}');

      setState(() {
        _expenses = expenses;
        _budgets = budgets;
        _isLoading = false;
      });
      print('setState done');
    } catch (e) {
      print('EXPENSES ERROR: $e');
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

  Future<void> _confirmDeleteExpense(Expense expense, int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text(
              'Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _apiService.deleteExpense(expense.id);
      setState(() {
        _expenses.removeAt(index);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not delete expense';
      });
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openEditExpenseScreen(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(existingExpense: expense),
      ),
    );

    if (result == true) {
      _loadExpenses();
    }
  }

  String? _budgetSummaryText() {
    if (_budgets.isEmpty) return null;
    final now = DateTime.now();
    int overBudgetCount = 0;
    for (final budget in _budgets) {
      final spent = _expenses
          .where((expense) {
            final expenseDate = DateTime.parse(expense.date);
            return expense.category == budget.category &&
                expenseDate.year == now.year &&
                expenseDate.month == now.month;
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);
      if (spent > budget.monthlyLimit) {
        overBudgetCount++;
      }
    }

    if (overBudgetCount == 0) {
      return '${_budgets.length} of ${_budgets.length} budgets on track';
    }
    return '$overBudgetCount of ${_budgets.length} budgets over limit';
  }

  Map<String, List<Expense>> _groupExpensesByMonth() {
    final Map<String, List<Expense>> grouped = {};

    for (final expense in _expenses) {
      final date = DateTime.parse(expense.date);
      final monthKey = '${_monthName(date.month)} ${date.year}';

      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(expense);
    }
    return grouped;
  }

  String _monthName(int month) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              _loadExpenses();
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
            tooltip: 'View Dashboard Data',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
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
      return const Center(child: Text('No expenses yet. Add your first one!'));
    }

    final summaryText = _budgetSummaryText();
    final grouped = _groupExpensesByMonth();
    final monthKeys = grouped.keys.toList();

    return Column(
      children: [
        if (summaryText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.teal.shade50,
            child: Text(
              summaryText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadExpenses,
            child: ListView.builder(
              itemCount: monthKeys.length,
              itemBuilder: (context, monthIndex) {
                final monthKey = monthKeys[monthIndex];
                final monthExpenses = grouped[monthKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        monthKey,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    ...monthExpenses.map((expense) {
                      final index = _expenses.indexOf(expense);
                      return ListTile(
                        title: Text(
                          expense.description.isNotEmpty
                              ? expense.description
                              : expense.categoryName,
                        ),
                        subtitle: Text(
                          '${expense.categoryName} [${expense.date}]',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'R${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit expense',
                              onPressed: () => _openEditExpenseScreen(expense),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete expense',
                              onPressed: () =>
                                  _confirmDeleteExpense(expense, index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
