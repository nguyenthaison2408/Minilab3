import 'package:flutter/material.dart';
import '../core/constants/app_categories.dart';
import '../core/database/db_helper.dart';
import '../models/ocr_result_model.dart';
import '../models/transaction_model.dart';
import '../services/ocr_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DbHelper _db = DbHelper.instance;

  List<TransactionModel> _transactions = [];
  Map<ExpenseCategory, double> _categoryExpenses = {
    for (var cat in ExpenseCategory.values) cat: 0.0,
  };
  List<Map<String, dynamic>> _weeklyExpenses = [];
  double _totalExpense = 0.0;

  bool _isLoading = false;
  bool _isOcrProcessing = false;
  String? _selectedCategoryFilter;
  String _searchQuery = '';

  // Getters
  List<TransactionModel> get transactions => _transactions;
  Map<ExpenseCategory, double> get categoryExpenses => _categoryExpenses;
  List<Map<String, dynamic>> get weeklyExpenses => _weeklyExpenses;
  double get totalExpense => _totalExpense;
  bool get isLoading => _isLoading;
  bool get isOcrProcessing => _isOcrProcessing;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;

  ExpenseProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadTransactions(),
        _loadAggregates(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTransactions() async {
    _transactions = await _db.getAllTransactions(
      categoryFilter: _selectedCategoryFilter,
    );

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      _transactions = _transactions.where((t) {
        return t.title.toLowerCase().contains(q) ||
            (t.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  Future<void> _loadAggregates() async {
    _totalExpense = await _db.getTotalExpense();
    _categoryExpenses = await _db.getCategoryExpenses();
    _weeklyExpenses = await _db.getLast7DaysExpenses();
  }

  void setCategoryFilter(String? category) {
    _selectedCategoryFilter = category;
    loadAllData();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _loadTransactions().then((_) => notifyListeners());
  }

  Future<bool> addTransaction(TransactionModel tx) async {
    try {
      await _db.insertTransaction(tx);
      await loadAllData();
      return true;
    } catch (e) {
      debugPrint('Error inserting transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel tx) async {
    try {
      await _db.updateTransaction(tx);
      await loadAllData();
      return true;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _db.deleteTransaction(id);
      await loadAllData();
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  /// Process receipt via OCR Service
  Future<OcrResultModel> scanReceipt(String imagePath) async {
    _isOcrProcessing = true;
    notifyListeners();

    try {
      final result = await OcrService.processReceiptImage(imagePath);
      return result;
    } finally {
      _isOcrProcessing = false;
      notifyListeners();
    }
  }
}

