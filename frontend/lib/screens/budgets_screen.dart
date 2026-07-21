import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/api_service.dart';

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
      final budgets = await _apiService.getBudgets();
      final categories = await _apiService.getCategories();

      setState(() {
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'R${budget.monthlyLimit.toStringAsFixed(2)}/month',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
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
                                          _confirmDeleteBudget(budget, index),
                                    ),
                                  ],
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
