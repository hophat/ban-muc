class Expense {
  final int id;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for compatibility
  String get expenseType => category;
  String get description => notes?.isNotEmpty == true ? notes! : _getDescriptionFromCategory();

  String _getDescriptionFromCategory() {
    switch (category) {
      case 'fuel': return 'Chi phí xăng dầu';
      case 'maintenance': return 'Chi phí bảo trì';
      case 'equipment': return 'Chi phí thiết bị';
      case 'salary': return 'Chi phí lương';
      case 'other': return 'Chi phí khác';
      default: return 'Chi phí $category';
    }
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: json['expense_type'] ?? 'other',
      amount: double.parse(json['amount'].toString()),
      expenseDate: DateTime.parse(json['expense_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_type': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 