import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../services/api_service.dart';
import '../utils/budget_period.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _apiService = ApiService();
  final _limitController = TextEditingController();

  List<Category> _categories = [];
  List<Budget> _budgets = [];
  Category? _selectedCategory;

  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;

  Budget? _editingBudget;
  bool get _isEditing => _editingBudget != null;

  Income? _income;
  final _incomeController = TextEditingController();
  bool _isEditingIncome = false;

  DateTime _currentPeriodStart = DateTime.now();
  final _cycleDayController = TextEditingController();
  bool _isEditingCycleDay = false;

  DateTime _viewingPeriodStart = DateTime.now();
  bool get _isViewingCurrentPeriod =>
      formatDate(_viewingPeriodStart) == formatDate(_currentPeriodStart);
  bool _hasInitializedPeriod = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
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

      final budgets = await _apiService.getBudgets(periodStart: periodStartStr);
      final categories = await _apiService.getCategories();

      setState(() {
        _income = income;
        _currentPeriodStart = actualCurrentPeriod;
        _budgets = budgets;
        _categories = categories;
        _isLoading = false;
        if (!_isEditing && categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load budgets';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddBudget() async {
    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    final limit = double.tryParse(_limitController.text);
    if (limit == null || limit <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    final alreadyExists = _budgets.any(
      (budget) =>
          budget.category == _selectedCategory!.id &&
          budget.id != _editingBudget?.id,
    );

    if (alreadyExists) {
      setState(() {
        _errorMessage = 'A budget for this category already exists';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final budget = Budget(
        id: _isEditing ? _editingBudget!.id : 0,
        category: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        monthlyLimit: limit,
        periodStart: formatDate(_currentPeriodStart),
      );

      if (_isEditing) {
        await _apiService.updateBudget(budget.id, budget);
      } else {
        await _apiService.createBudget(budget);
      }
      _limitController.clear();
      _editingBudget = null;
      await _loadBudgets();
    } catch (e) {
      setState(() {
        _errorMessage = _isEditing
            ? 'Could not update budget'
            : 'Could not save budget';
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _confirmDeleteBudget(Budget budget, int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Budget'),
            content: Text('Are you sure you want to delete this budget?'),
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
      await _apiService.deleteBudget(budget.id);
      setState(() {
        _budgets.removeAt(index);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not delete budget';
      });
    }
  }

  void _startEditingBudget(Budget budget) {
    setState(() {
      _editingBudget = budget;
      _limitController.text = budget.monthlyLimit.toString();
      _selectedCategory = _categories.firstWhere(
        (category) => category.id == budget.category,
        orElse: () => _categories.first,
      );
      _errorMessage = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingBudget = null;
      _limitController.clear();
      _errorMessage = null;
    });
  }

  double _totalAllocated() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.monthlyLimit);
  }

  void _startEditingIncome() {
    setState(() {
      _isEditingIncome = true;
      _incomeController.text = _income?.monthlyIncome.toString() ?? '0';
    });
  }

  void _goToPreviousPeriod() {
    final cycleDay = _income?.budgetCycleDay ?? 1;
    setState(() {
      _viewingPeriodStart = getPreviousPeriodStart(
        _viewingPeriodStart,
        cycleDay,
      );
    });
    _loadBudgets();
  }

  void _goToCurrentPeriod() {
    setState(() {
      _viewingPeriodStart = _currentPeriodStart;
    });
    _loadBudgets();
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_incomeController.text);
    if (amount == null || amount < 0) {
      setState(() {
        _errorMessage = 'Please enter a valid income amount';
      });
      return;
    }

    try {
      final updated = Income(
        id: _income!.id,
        monthlyIncome: amount,
        budgetCycleDay: _income?.budgetCycleDay ?? 1,
      );
      final updatedIncome = await _apiService.updateIncome(updated);
      setState(() {
        _income = updatedIncome;
        _isEditingIncome = false;
        _errorMessage = null;
      });
      await _loadBudgets();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not update income';
      });
    }
  }

  Widget _buildIncomeSummary() {
    final income = _income?.monthlyIncome ?? 0;
    final allocated = _totalAllocated();
    final remaining = income - allocated;
    final ratio = income > 0 ? (allocated / income).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Income',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!_isEditingIncome)
                TextButton(
                  onPressed: _startEditingIncome,
                  child: const Text('Edit'),
                ),
            ],
          ),
          if (_isEditingIncome) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'R',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveIncome,
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            Text(
              'R${income.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining < 0 ? Colors.red : Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              remaining < 0
                  ? 'R${(-remaining).toStringAsFixed(2)} over-allocated'
                  : 'R${remaining.toStringAsFixed(2)} unallocated · R${allocated.toStringAsFixed(2)} budgeted',
              style: TextStyle(
                fontSize: 13,
                color: remaining < 0 ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodNavigator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
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
          if (!_isEditingCycleDay)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingCycleDay = true;
                  _cycleDayController.text =
                      _income?.budgetCycleDay.toString() ?? '1';
                });
              },
              child: const Text('Change cycle day'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveCycleDay() async {
    final day = int.tryParse(_cycleDayController.text);
    if (day == null || day < 1 || day > 31) {
      setState(() {
        _errorMessage = 'Please enter a day between 1 and 31';
      });
      return;
    }

    try {
      final updated = Income(
        id: _income!.id,
        monthlyIncome: _income!.monthlyIncome,
        budgetCycleDay: day,
      );
      await _apiService.updateIncome(updated);
      setState(() {
        _isEditingCycleDay = false;
      });
      await _loadBudgets();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not update budget cycle day';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Budget' : 'Add Budget')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIncomeSummary(),
                  _buildPeriodNavigator(),
                  if (_isEditingCycleDay)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cycleDayController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cycle start day (1-31)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveCycleDay,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Add/Edit form — only shown and usable while viewing the current period.
                  if (_isViewingCurrentPeriod) ...[
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Limit',
                        prefixText: 'R',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isAdding ? null : _handleAddBudget,
                      child: _isAdding
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Update Budget' : 'Save Budget'),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cancel edit',
                        onPressed: _cancelEditing,
                      ),
                    ],
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Viewing a past period — budgets can only be edited for the current period.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _budgets.isEmpty
                        ? const Center(child: Text('No budgets set yet'))
                        : ListView.builder(
                            itemCount: _budgets.length,
                            itemBuilder: (context, index) {
                              final budget = _budgets[index];
                              return ListTile(
                                title: Text(budget.categoryName),
                                trailing: _isViewingCurrentPeriod
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'R${budget.monthlyLimit.toStringAsFixed(2)}/month',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            tooltip: 'Edit Budget',
                                            onPressed: () =>
                                                _startEditingBudget(budget),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Delete budget',
                                            onPressed: () =>
                                                _confirmDeleteBudget(
                                                  budget,
                                                  index,
                                                ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'R${budget.monthlyLimit.toStringAsFixed(2)}/month',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
