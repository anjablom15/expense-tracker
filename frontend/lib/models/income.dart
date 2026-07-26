class Income {
  final int id;
  final double monthlyIncome;
  final int budgetCycleDay;

  Income({
    required this.id,
    required this.monthlyIncome,
    required this.budgetCycleDay,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      monthlyIncome: double.parse(json['monthly_income'].toString()),
      budgetCycleDay: json['budget_cycle_day'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_income': monthlyIncome,
      'budget_cycle_day': budgetCycleDay,
    };
  }
}
