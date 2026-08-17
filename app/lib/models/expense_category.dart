class ExpenseCategory {
  final int? id;
  final String name;

  const ExpenseCategory({
    this.id,
    required this.name,
  });

  ExpenseCategory copyWith({int? id, String? name}) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  /// Normalizes a category name for consistent storage and comparison.
  static String normalize(String name) {
    return name.trim();
  }

  /// Returns true if [name] is blank after trimming.
  static bool isBlankName(String name) {
    return name.trim().isEmpty;
  }
}
