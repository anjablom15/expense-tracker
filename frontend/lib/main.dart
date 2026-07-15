import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Expense Tracker - Coming Soon!')),
      ),
    );
  }
}
