import '../core/constants/app_categories.dart';

class OcrResultModel {
  final String? merchant;
  final DateTime? date;
  final double? amount;
  final String rawText;
  final List<String> detectedLines;
  final ExpenseCategory suggestedCategory;
  final String? confidenceNotes;

  OcrResultModel({
    this.merchant,
    this.date,
    this.amount,
    required this.rawText,
    required this.detectedLines,
    this.suggestedCategory = ExpenseCategory.food,
    this.confidenceNotes,
  });

  bool get hasValidData => amount != null || merchant != null || date != null;

  OcrResultModel copyWith({
    String? merchant,
    DateTime? date,
    double? amount,
    String? rawText,
    List<String>? detectedLines,
    ExpenseCategory? suggestedCategory,
    String? confidenceNotes,
  }) {
    return OcrResultModel(
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      rawText: rawText ?? this.rawText,
      detectedLines: detectedLines ?? this.detectedLines,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      confidenceNotes: confidenceNotes ?? this.confidenceNotes,
    );
  }
}

