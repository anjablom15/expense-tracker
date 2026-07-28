import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/income.dart';
import '../services/api_service.dart';
import '../utils/budget_period.dart';
import 'add_expense_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();

  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  Income? _income;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _currentPeriodStart = DateTime.now();
  DateTime _viewingPeriodStart = DateTime.now();
  bool _hasInitializedPeriod = false;

  bool get _isViewingCurrentPeriod =>
      formatDate(_viewingPeriodStart) == formatDate(_currentPeriodStart);

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
      final income = await _apiService.getIncome();
      final actualCurrentPeriod = getCurrentPeriodStart(income.budgetCycleDay);

      if (!_hasInitializedPeriod) {
        _viewingPeriodStart = actualCurrentPeriod;
        _hasInitializedPeriod = true;
      }

      final periodStartStr = formatDate(_viewingPeriodStart);

      final expenses = await _apiService.getExpenses();
      final budgets = await _apiService.getBudgets(periodStart: periodStartStr);

      setState(() {
        _income = income;
        _currentPeriodStart = actualCurrentPeriod;
        _expenses = expenses;
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load dashboard data';
        _isLoading = false;
      });
    }
  }

  void _goToPreviousPeriod() {
    final cycleDay = _income?.budgetCycleDay ?? 1;
    setState(() {
      _viewingPeriodStart = getPreviousPeriodStart(
        _viewingPeriodStart,
        cycleDay,
      );
    });
    _loadData();
  }

  void _goToCurrentPeriod() {
    setState(() {
      _viewingPeriodStart = _currentPeriodStart;
    });
    _loadData();
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

  Future<void> _openAddExpenseScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  List<Expense> _expensesForViewingPeriod() {
    final periodEnd = getPeriodEnd(_viewingPeriodStart);
    return _expenses.where((expense) {
      final date = DateTime.parse(expense.date);
      return !date.isBefore(_viewingPeriodStart) && !date.isAfter(periodEnd);
    }).toList();
  }

  Map<String, double> _totalsByCategory() {
    final Map<String, double> totals = {};
    for (final expense in _expensesForViewingPeriod()) {
      totals.update(
        expense.categoryName,
        (existing) => existing + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  double _totalSpent() {
    return _expensesForViewingPeriod().fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double _spentForCategory(int categoryId) {
    return _expensesForViewingPeriod()
        .where((expense) => expense.category == categoryId)
        .fold(0.0, (sum, expense) => sum + expense.amount);
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Expenses',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              _loadData();
            },
          ),
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
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Manage Budgets',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _expenses.isEmpty
          ? const Center(child: Text('No expenses yet to show'))
          : _buildDashboard(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboard() {
    final totals = _totalsByCategory();
    final total = _totalSpent();

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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous period',
                onPressed: _goToPreviousPeriod,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${formatDate(_viewingPeriodStart)} to ${formatDate(getPeriodEnd(_viewingPeriodStart))}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (!_isViewingCurrentPeriod)
                      TextButton(
                        onPressed: _goToCurrentPeriod,
                        child: const Text('Back to current period'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBudgetSummary(),
          Text(
            'Total spent: R${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (categoryNames.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No expenses in this period')),
            )
          else ...[
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
        ],
      ),
    );
  }
}
