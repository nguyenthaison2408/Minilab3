import '../core/constants/app_categories.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? note;
  final String? rawOcrText;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImagePath,
    this.note,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.nameString,
      'receiptImagePath': receiptImagePath,
      'note': note,
      'rawOcrText': rawOcrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Khoản chi tiêu',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      category: ExpenseCategoryExtension.fromString(
        map['category'] as String? ?? 'Food',
      ),
      receiptImagePath: map['receiptImagePath'] as String?,
      note: map['note'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? note,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      note: note ?? this.note,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

