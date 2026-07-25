class Income {
  final int id;
  final double monthlyIncome;

  Income({required this.id, required this.monthlyIncome});

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      monthlyIncome: double.parse(json['monthly_income'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {'monthly_income': monthlyIncome};
  }
}
