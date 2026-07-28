class Expense {
  final int? id;
  final DateTime date;
  final String description;
  final double amount;

  Expense({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
