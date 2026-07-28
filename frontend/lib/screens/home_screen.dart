import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../screens/add_expense_screen.dart';

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
      appBar: AppBar(title: const Text('My Expenses')),
      body: _buildBody(),
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

    final grouped = _groupExpensesByMonth();
    final monthKeys = grouped.keys.toList();

    return RefreshIndicator(
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
                  subtitle: Text('${expense.categoryName} [${expense.date}]'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'R${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                        onPressed: () => _confirmDeleteExpense(expense, index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
