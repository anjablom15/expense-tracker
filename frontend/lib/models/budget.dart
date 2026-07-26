class Budget {
  final int id;
  final int category;
  final String categoryName;
  final double monthlyLimit;
  final String periodStart;

  Budget({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.monthlyLimit,
    required this.periodStart,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      monthlyLimit: double.parse(json['monthly_limit'].toString()),
      periodStart: json['period_start'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'monthly_limit': monthlyLimit};
  }
}
