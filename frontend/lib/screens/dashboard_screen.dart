import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
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
        _errorMessage = 'Could not load dashboard data';
        _isLoading = false;
      });
    }
  }

  Map<String, double> _totalsByCategory() {
    final Map<String, double> totals = {};
    for (final expense in _expenses) {
      totals.update(
        expense.categoryName,
        (existing) => existing + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  double _totalSpent() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
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
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.green,
    ];

    final categoryNames = totals.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
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
          ),
        ],
      ),
    );
  }
}
