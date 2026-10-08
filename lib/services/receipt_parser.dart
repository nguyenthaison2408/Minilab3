import '../core/constants/app_categories.dart';
import '../models/ocr_result_model.dart';

class ReceiptParser {
  /// Known merchants and their default category mappings
  static final Map<String, ExpenseCategory> _knownMerchants = {
    'winmart': ExpenseCategory.food,
    'co.opmart': ExpenseCategory.food,
    'coopmart': ExpenseCategory.food,
    'circle k': ExpenseCategory.food,
    'highlands': ExpenseCategory.food,
    'phúc long': ExpenseCategory.food,
    'phuc long': ExpenseCategory.food,
    'starbucks': ExpenseCategory.food,
    'the coffee house': ExpenseCategory.food,
    'kfc': ExpenseCategory.food,
    'lotteria': ExpenseCategory.food,
    'mcdonald': ExpenseCategory.food,
    'jollibee': ExpenseCategory.food,
    'bách hoá xanh': ExpenseCategory.food,
    'bach hoa xanh': ExpenseCategory.food,
    'ministop': ExpenseCategory.food,
    'family mart': ExpenseCategory.food,
    'familymart': ExpenseCategory.food,
    'gs25': ExpenseCategory.food,
    '7-eleven': ExpenseCategory.food,
    'seven eleven': ExpenseCategory.food,
    'lotte mart': ExpenseCategory.food,
    'lotte': ExpenseCategory.food,
    'big c': ExpenseCategory.food,
    'go!': ExpenseCategory.food,
    'aeon': ExpenseCategory.food,
    'cơm tấm': ExpenseCategory.food,
    'phở': ExpenseCategory.food,
    'trà sữa': ExpenseCategory.food,
    'fahasa': ExpenseCategory.study,
    'phương nam': ExpenseCategory.study,
    'nhà sách': ExpenseCategory.study,
    'tiền phong': ExpenseCategory.study,
    'grab': ExpenseCategory.travel,
    'be': ExpenseCategory.travel,
    'xanh sm': ExpenseCategory.travel,
    'petrolimex': ExpenseCategory.travel,
    'cây xăng': ExpenseCategory.travel,
    'gearvn': ExpenseCategory.gear,
    'fpt shop': ExpenseCategory.gear,
    'thegioididong': ExpenseCategory.gear,
    'thế giới di động': ExpenseCategory.gear,
    'cellphones': ExpenseCategory.gear,
    'cgv': ExpenseCategory.entertainment,
    'lotte cinema': ExpenseCategory.entertainment,
    'bhd': ExpenseCategory.entertainment,
    'galaxy cinema': ExpenseCategory.entertainment,
  };

  /// Parse lines of text extracted from OCR into structured receipt data
  static OcrResultModel parse(String fullText, List<String> rawLines) {
    // Filter and clean lines
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final date = _extractDate(lines, fullText);
    final amount = _extractTotalAmount(lines, fullText);
    final category = _suggestCategory(merchant, fullText);

    return OcrResultModel(
      merchant: merchant,
      date: date,
      amount: amount,
      rawText: fullText,
      detectedLines: lines,
      suggestedCategory: category,
      confidenceNotes: _buildConfidenceNotes(merchant, date, amount),
    );
  }

  /// 1. Extract Merchant Name using Header Heuristics & Brand Dictionary
  static String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    // First scan top 6 lines against known brand names
    final topLines = lines.take(6).toList();
    for (final line in topLines) {
      final lower = line.toLowerCase();
      for (final brand in _knownMerchants.keys) {
        if (lower.contains(brand)) {
          return line;
        }
      }
    }

    // Heuristic: Pick the first non-meta header line (skip address, phone, tax code, invoice title)
    for (final line in topLines) {
      final lower = line.toLowerCase();
      if (_isMetaOrHeaderLine(lower)) continue;
      if (line.length >= 3 && line.length <= 45) {
        return line;
      }
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng';
  }

  static bool _isMetaOrHeaderLine(String lower) {
    return lower.contains('đ/c') ||
        lower.contains('địa chỉ') ||
        lower.contains('address') ||
        lower.contains('tel:') ||
        lower.contains('đt:') ||
        lower.contains('phone') ||
        lower.contains('hotline') ||
        lower.contains('mst') ||
        lower.contains('mã số thuế') ||
        lower.contains('hoá đơn') ||
        lower.contains('hóa đơn') ||
        lower.contains('phiếu thanh toán') ||
        lower.contains('receipt') ||
        lower.contains('invoice') ||
        lower.contains('tax') ||
        lower.startsWith('no:') ||
        lower.startsWith('số:');
  }

  /// 2. Extract Transaction Date using regex heuristics
  static DateTime? _extractDate(List<String> lines, String fullText) {
    // Regex for Vietnamese text date: "Ngày 15 tháng 10 năm 2026"
    final vnTextDateRegex = RegExp(
      r'ngày\s+(\d{1,2})\s+tháng\s+(\d{1,2})\s+năm\s+(\d{4})',
      caseSensitive: false,
    );
    final vnMatch = vnTextDateRegex.firstMatch(fullText);
    if (vnMatch != null) {
      final d = int.tryParse(vnMatch.group(1)!);
      final m = int.tryParse(vnMatch.group(2)!);
      final y = int.tryParse(vnMatch.group(3)!);
      if (_isValidDate(d, m, y)) {
        return DateTime(y!, m!, d!);
      }
    }

    // Standard date patterns: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, YYYY/MM/DD
    final dateRegex = RegExp(
      r'\b(\d{1,4})[./-](\d{1,2})[./-](\d{2,4})\b',
    );

    // Prefer lines containing date-related keywords
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngày') ||
          lower.contains('date') ||
          lower.contains('time') ||
          lower.contains('giờ')) {
        final matches = dateRegex.allMatches(line);
        for (final m in matches) {
          final parsed = _tryParseDateMatch(m);
          if (parsed != null) return parsed;
        }
      }
    }

    // Scan all lines if not found in keyword lines
    for (final line in lines) {
      final matches = dateRegex.allMatches(line);
      for (final m in matches) {
        final parsed = _tryParseDateMatch(m);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static DateTime? _tryParseDateMatch(Match m) {
    int? p1 = int.tryParse(m.group(1)!);
    int? p2 = int.tryParse(m.group(2)!);
    int? p3 = int.tryParse(m.group(3)!);

    if (p1 == null || p2 == null || p3 == null) return null;

    // Handle 2-digit years like 26 -> 2026
    if (p3 < 100) p3 += 2000;
    if (p1 < 100 && p1 > 31) p1 += 2000;

    // Format: YYYY-MM-DD
    if (p1 >= 2000 && p1 <= 2035) {
      if (_isValidDate(p3, p2, p1)) {
        return DateTime(p1, p2, p3);
      }
    }

    // Format: DD-MM-YYYY
    if (_isValidDate(p1, p2, p3)) {
      return DateTime(p3, p2, p1);
    }

    return null;
  }

  static bool _isValidDate(int? d, int? m, int? y) {
    if (d == null || m == null || y == null) return false;
    if (y < 2015 || y > 2035) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    return true;
  }

  /// 3. Extract Total Amount using monetary regex and keyword heuristics
  static double? _extractTotalAmount(List<String> lines, String fullText) {
    final primaryTotalKeywords = [
      'tổng thanh toán',
      'tổng cộng',
      'thành tiền',
      'tổng tiền',
      'tong cong',
      'thanh tien',
      'tong tien',
      'amount due',
      'balance due',
      'total amount',
      'grand total',
      'total',
      'cần thanh toán',
      'khách phải trả',
      'phải thanh toán',
    ];

    // Priority 1: Match directly inside lines having primary total keywords
    for (final kw in primaryTotalKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        if (lower.contains(kw)) {
          // Check this line for money numbers
          double? amount = _extractHighestMoneyFromLine(line);
          if (amount != null && amount > 0) {
            return amount;
          }
          // Also check the immediately next line (often total value is printed on next line)
          if (i + 1 < lines.length) {
            double? nextAmount = _extractHighestMoneyFromLine(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) {
              return nextAmount;
            }
          }
        }
      }
    }

    // Secondary keywords (Cộng, Tiền mặt, v.v.)
    final secondaryKeywords = ['cộng', 'thanh toán', 'payment', 'cash'];
    for (final kw in secondaryKeywords) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (lower.contains(kw) && !lower.contains('tiền thối') && !lower.contains('tiền thừa')) {
          double? amount = _extractHighestMoneyFromLine(line);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }

    // Fallback heuristic: Find all money values in lower 60% of the receipt lines
    List<double> candidates = [];
    int startIdx = (lines.length * 0.35).toInt();
    for (int i = startIdx; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      // Skip discount, tax rate, change returned, card number, phone number
      if (lower.contains('thối') ||
          lower.contains('thừa') ||
          lower.contains('change') ||
          lower.contains('vat 8%') ||
          lower.contains('vat 10%')) {
        continue;
      }
      final val = _extractHighestMoneyFromLine(line);
      if (val != null && val >= 1000 && val <= 50000000) {
        candidates.add(val);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a));
      return candidates.first;
    }

    return null;
  }

  /// Extracts the best monetary number from a single line
  static double? _extractHighestMoneyFromLine(String line) {
    // Regex for Vietnamese & international currency formats:
    // Examples: 150.000, 150,000, 150 000, 150.000đ, 150,000 VND
    final moneyRegex = RegExp(
      r'(?:[\$đ₫]|vnd|vnđ)?\s*([0-9]{1,3}(?:[.,\s][0-9]{3})+(?:[.,][0-9]{1,2})?|[0-9]{4,8})\s*(?:[\$đ₫]|vnd|vnđ)?',
      caseSensitive: false,
    );

    final matches = moneyRegex.allMatches(line);
    double? maxVal;

    for (final m in matches) {
      String rawNum = m.group(1) ?? '';
      // Clean up separators: replace spaces, normalize dots and commas
      String clean = rawNum.replaceAll(' ', '');

      // Heuristic for Vietnamese thousand separator:
      // If it ends with .000 or ,000, e.g. 150.000 -> 150000
      if (clean.contains('.') && !clean.contains(',')) {
        clean = clean.replaceAll('.', '');
      } else if (clean.contains(',') && !clean.contains('.')) {
        clean = clean.replaceAll(',', '');
      } else if (clean.contains('.') && clean.contains(',')) {
        // e.g. 150,000.00 or 150.000,00
        if (clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
          clean = clean.replaceAll(',', '');
        } else {
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        }
      }

      final parsed = double.tryParse(clean);
      if (parsed != null && parsed >= 500 && parsed <= 100000000) {
        if (maxVal == null || parsed > maxVal) {
          maxVal = parsed;
        }
      }
    }

    return maxVal;
  }

  /// 4. Suggest Expense Category from merchant name and text keywords
  static ExpenseCategory _suggestCategory(String? merchant, String fullText) {
    if (merchant != null) {
      final lowerMerchant = merchant.toLowerCase();
      for (final entry in _knownMerchants.entries) {
        if (lowerMerchant.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    final lowerText = fullText.toLowerCase();

    // Food indicators
    if (lowerText.contains('cà phê') ||
        lowerText.contains('coffee') ||
        lowerText.contains('trà') ||
        lowerText.contains('tea') ||
        lowerText.contains('bánh') ||
        lowerText.contains('mì') ||
        lowerText.contains('thực phẩm') ||
        lowerText.contains('suất ăn') ||
        lowerText.contains('food')) {
      return ExpenseCategory.food;
    }

    // Study indicators
    if (lowerText.contains('sách') ||
        lowerText.contains('bút') ||
        lowerText.contains('vở') ||
        lowerText.contains('học phí') ||
        lowerText.contains('photo') ||
        lowerText.contains('in ấn') ||
        lowerText.contains('book')) {
      return ExpenseCategory.study;
    }

    // Travel indicators
    if (lowerText.contains('xăng') ||
        lowerText.contains('grab') ||
        lowerText.contains('vé xe') ||
        lowerText.contains('taxi') ||
        lowerText.contains('phí đỗ xe') ||
        lowerText.contains('gửi xe')) {
      return ExpenseCategory.travel;
    }

    // Gear indicators
    if (lowerText.contains('chuột') ||
        lowerText.contains('bàn phím') ||
        lowerText.contains('tai nghe') ||
        lowerText.contains('sạc') ||
        lowerText.contains('cáp') ||
        lowerText.contains('điện thoại') ||
        lowerText.contains('laptop') ||
        lowerText.contains('linh kiện')) {
      return ExpenseCategory.gear;
    }

    // Entertainment indicators
    if (lowerText.contains('cinema') ||
        lowerText.contains('rạp') ||
        lowerText.contains('phim') ||
        lowerText.contains('vé vào cổng') ||
        lowerText.contains('bida') ||
        lowerText.contains('game')) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food;
  }

  static String _buildConfidenceNotes(String? merchant, DateTime? date, double? amount) {
    List<String> found = [];
    if (merchant != null) found.add('Cửa hàng');
    if (date != null) found.add('Ngày');
    if (amount != null) found.add('Số tiền');

    if (found.length == 3) {
      return 'Trích xuất thành công đầy đủ (${found.join(", ")})';
    } else if (found.isNotEmpty) {
      return 'Đã tìm thấy: ${found.join(", ")}. Vui lòng kiểm tra lại.';
    } else {
      return 'Chưa nhận diện rõ ràng, bạn có thể điền thủ công.';
    }
  }
}

