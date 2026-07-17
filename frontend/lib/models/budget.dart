//import 'package:flutter/foundation.dart';

class Budget {
  final int id;
  final int category;
  final String categoryName;
  final double monthlyLimit;

  Budget({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.monthlyLimit,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      categoryName: json['category_name'],
      monthlyLimit: double.parse(json['monthly_limit'].toString()),
    );
  }

  // Category is not sent back to Django, because Django only sends it to Dart for convenience, so that the Category NAME
  // is displayed, rather than the category id, ex. 3 instead of "Groceries".
  // Django does not need the category name, for it already knows the id.

  Map<String, dynamic> toJson() {
    return {'category': category, 'monthly_limit': monthlyLimit};
  }
}
