class Expense {
  final int id;
  final int category;
  final String categoryName;
  final double amount;
  final String description;
  final String date;

  Expense({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      amount: double.parse(json['amount'].toString()),
      description: json['description'] ?? '',
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
    };
  }
}
