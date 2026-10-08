import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/constants/app_categories.dart';
import 'package:ocr_expense_tracker/core/utils/currency_formatter.dart';
import 'package:ocr_expense_tracker/core/utils/date_formatter.dart';
import 'package:ocr_expense_tracker/models/transaction_model.dart';
import 'package:ocr_expense_tracker/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Regex Heuristic Engine Tests', () {
    test('Correctly parses WinMart receipt total, merchant, date, and category', () {
      const rawText = '''WINMART+ CONG HOA
Dia chi: 123 Cong Hoa, Tan Binh, HCM
Tel: 028.38123456
HD so: 0092837
Ngay: 15/10/2026 14:30
-------------------------------
Sua chua Vinamilk      35.000
Banh mi Sandwich       22.000
Trai cay nhap khau    128.000
-------------------------------
TONG CONG: 185.000 đ
Tien mat: 200.000 đ
Tien thoi: 15.000 đ
Cam on quy khach!''';

      final lines = rawText.split('\n');
      final result = ReceiptParser.parse(rawText, lines);

      expect(result.amount, equals(185000.0));
      expect(result.date, equals(DateTime(2026, 10, 15)));
      expect(result.merchant?.toLowerCase(), contains('winmart'));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Correctly parses Highlands Coffee receipt total with comma and VND', () {
      const rawText = '''HIGHLANDS COFFEE
Chi nhanh: Landmark 81
Date: 12-10-2026 09:15
Order #104
-------------------------------
1 Phin Sua Da (L)       45,000
1 Banh Mi Thit Nuong    30,000
-------------------------------
TOTAL: 75,000 VND
Payment: Momo
Thank you and see you again!''';

      final lines = rawText.split('\n');
      final result = ReceiptParser.parse(rawText, lines);

      expect(result.amount, equals(75000.0));
      expect(result.date, equals(DateTime(2026, 10, 12)));
      expect(result.merchant?.toLowerCase(), contains('highlands'));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Correctly parses Fahasa Bookstore and infers Study category', () {
      const rawText = '''NHA SACH FAHASA
D/c: Nguyen Hue, Quan 1, TP.HCM
Ngay: 08/10/2026 16:45
-------------------------------
Giao trinh Flutter 3   180.000
So tay ghi chu          65.000
-------------------------------
THANH TIEN: 245.000 đ
Khach da tra: 245.000 đ''';

      final lines = rawText.split('\n');
      final result = ReceiptParser.parse(rawText, lines);

      expect(result.amount, equals(245000.0));
      expect(result.date, equals(DateTime(2026, 10, 8)));
      expect(result.merchant?.toLowerCase(), contains('fahasa'));
      expect(result.suggestedCategory, equals(ExpenseCategory.study));
    });
  });

  group('Currency & Date Formatter Tests', () {
    test('Formats VND properly', () {
      final formatted = CurrencyFormatter.formatVND(150000);
      expect(formatted, contains('150.000'));
    });

    test('Parses date DD/MM/YYYY properly', () {
      final dt = DateFormatter.parse('15/10/2026');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(10));
      expect(dt.day, equals(15));
    });
  });

  group('TransactionModel Tests', () {
    test('Map serialization and deserialization', () {
      final tx = TransactionModel(
        id: 1,
        title: 'Cà phê sáng',
        amount: 35000,
        date: DateTime(2026, 10, 8),
        category: ExpenseCategory.food,
        note: 'Cà phê đen',
      );

      final map = tx.toMap();
      final restored = TransactionModel.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.title, equals('Cà phê sáng'));
      expect(restored.amount, equals(35000));
      expect(restored.category, equals(ExpenseCategory.food));
    });
  });
}
