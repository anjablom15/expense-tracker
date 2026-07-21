import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _apiService = ApiService();
  final _newCategoryController = TextEditingController();

  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;

  Category? _editingCategory;
  bool get _isEditing => _editingCategory != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _startEditingCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _newCategoryController.text = category.name;
      _errorMessage = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCategory = null;
      _newCategoryController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load categories';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    final alreadyExists = _categories.any(
      (category) =>
          category.name.toLowerCase() == name.toLowerCase() &&
          category.id != _editingCategory?.id,
    );

    if (alreadyExists) {
      setState(() {
        _errorMessage = 'This category already exists';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final category = Category(
        id: _isEditing ? _editingCategory!.id : 0,
        name: name,
      );
      if (_isEditing) {
        await _apiService.updateCategory(category.id, category);
      } else {
        await _apiService.createCategory(category);
      }
      _newCategoryController.clear();
      _editingCategory = null;
      await _loadCategories();
    } catch (e) {
      setState(() {
        _errorMessage = _isEditing
            ? 'Could not update category'
            : 'Could not save category';
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _confirmDeleteCategory(Category category, int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: const Text(
              'Are you sure you want to delete this category?',
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
      await _apiService.deleteCategory(category.id);
      setState(() {
        _categories.removeAt(index);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not delete category';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAdding ? null : _handleAddCategory,
                  child: _isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Category' : 'Save Category'),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel edit',
                    onPressed: _cancelEditing,
                  ),
                ],
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? const Center(child: Text('No categories yet'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ListTile(
                          title: Text(category.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Category',
                                onPressed: () =>
                                    _startEditingCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Category',
                                onPressed: () =>
                                    _confirmDeleteCategory(category, index),
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
