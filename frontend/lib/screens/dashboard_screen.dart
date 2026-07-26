import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();

  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expenses = await _apiService.getExpenses();
      final budgets = await _apiService.getBudgets();
      setState(() {
        _expenses = expenses;
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      print('DASHBOARD ERROR: $e');
      setState(() {
        _errorMessage = 'Could not load dashboard data';
        _isLoading = false;
      });
    }
  }

  Map<String, double> _totalsByCategory() {
    final Map<String, double> totals = {};
    for (final expense in _expensesForSelectedMonth()) {
      totals.update(
        expense.categoryName,
        (existing) => existing + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  double _totalSpent() {
    return _expensesForSelectedMonth().fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double _spentForCategory(int categoryId) {
    return _expensesForSelectedMonth()
        .where((expense) => expense.category == categoryId)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<DateTime> _availableMonths() {
    final Set<DateTime> months = {};

    for (final expense in _expenses) {
      final date = DateTime.parse(expense.date);
      months.add(DateTime(date.year, date.month));
    }

    final list = months.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Expense> _expensesForSelectedMonth() {
    return _expenses.where((expense) {
      final date = DateTime.parse(expense.date);
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList();
  }

  String _monthLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildBudgetSummary() {
    if (_budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Budgets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._budgets.map((budget) {
          final spent = _spentForCategory(budget.category);
          final limit = budget.monthlyLimit;
          final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
          final isOverBudget = spent > limit;

          Color barColor;
          if (isOverBudget) {
            barColor = Colors.red;
          } else if (ratio >= 0.8) {
            barColor = Colors.orange;
          } else {
            barColor = Colors.green;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOverBudget
                      ? 'R${(spent - limit).toStringAsFixed(2)} over budget'
                      : 'R${(limit - spent).toStringAsFixed(2)} left of R${limit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverBudget ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _expenses.isEmpty
          ? const Center(child: Text('No expenses yet to show'))
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final totals = _totalsByCategory();
    final total = _totalSpent();
    final availableMonths = _availableMonths();

    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.green,
    ];

    final categoryNames = totals.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<DateTime>(
            value: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            items: availableMonths.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(_monthLabel(month)),
              );
            }).toList(),
            onChanged: (month) {
              if (month != null) {
                setState(() {
                  _selectedMonth = month;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          _buildBudgetSummary(),
          Text(
            'Total spent: R${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: List.generate(categoryNames.length, (index) {
                  final name = categoryNames[index];
                  final amount = totals[name]!;
                  final percentage = (amount / total) * 100;
                  return PieChartSectionData(
                    value: amount,
                    color: colors[index % colors.length],
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 70,
                    titlePositionPercentageOffset: 1.3,
                    titleStyle: TextStyle(
                      color: colors[index % colors.length],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryNames.length,
            itemBuilder: (context, index) {
              final name = categoryNames[index];
              final amount = totals[name]!;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors[index % colors.length],
                  radius: 8,
                ),
                title: Text(name),
                trailing: Text('R${amount.toStringAsFixed(2)}'),
              );
            },
          ),
        ],
      ),
    );
  }
}
