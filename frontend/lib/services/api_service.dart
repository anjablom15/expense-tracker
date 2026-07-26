import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ApiService {
  static const String baseUrl =
      'https://expense-tracker-api-ut1p.onrender.com/api';

  // Every request, except login itself, needs to prove who the user is,
  // by attaching the access token in a specific format: Authorization: Bearer<token>.
  // These two functions grab the saved token and builds the header automatically, so this
  // logic does not need to be repeated in every single function.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =============== Authentication ===============

  Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      return null;
    } else {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        return data['error'];
      }
      if (data['password'] != null) {
        return data['password'][0];
      }
      return 'Registration failed';
    }
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('https://expense-tracker-api-ut1p.onrender.com/api/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // =============== Expenses ===============

  Future<List<Expense>> getExpenses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Expense.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/'),
      headers: await _getHeaders(),
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense');
    }
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    final response = await http.put(
      Uri.parse('$baseUrl/expenses/$id/'),
      headers: await _getHeaders(),
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update expense');
    }
  }

  // =============== Categories ===============

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories.');
    }
  }

  Future<Category> createCategory(Category category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/'),
      headers: await _getHeaders(),
      body: jsonEncode(category.toJson()),
    );

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create category');
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  Future<Category> updateCategory(int id, Category category) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id/'),
      headers: await _getHeaders(),
      body: jsonEncode(category.toJson()),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update categories');
    }
  }

  // =============== Budget ===============

  Future<List<Budget>> getBudgets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/budgets/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Budget.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load budgets');
    }
  }

  Future<Budget> createBudget(Budget budget) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budgets/'),
      headers: await _getHeaders(),
      body: jsonEncode(budget.toJson()),
    );

    if (response.statusCode == 201) {
      return Budget.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create budget');
    }
  }

  Future<void> deleteBudget(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/budgets/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete budget');
    }
  }

  Future<Budget> updateBudget(int id, Budget budget) async {
    final response = await http.put(
      Uri.parse('$baseUrl/budgets/$id/'),
      headers: await _getHeaders(),
      body: jsonEncode(budget.toJson()),
    );

    if (response.statusCode == 200) {
      return Budget.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update Budget');
    }
  }

  // =============== Income ===============

  Future<Income> getIncome() async {
    final response = await http.get(
      Uri.parse('$baseUrl/income/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Income.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load income');
    }
  }

  Future<Income> updateIncome(double amount) async {
    final response = await http.put(
      Uri.parse('$baseUrl/income/'),
      headers: await _getHeaders(),
      body: jsonEncode({'monthly_income': amount}),
    );

    if (response.statusCode == 200) {
      return Income.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update income');
    }
  }
}
