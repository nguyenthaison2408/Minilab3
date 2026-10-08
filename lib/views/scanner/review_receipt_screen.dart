import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/ocr_result_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/expense_provider.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final String? imagePath;
  final OcrResultModel ocrResult;
  final TransactionModel? existingTransaction;

  const ReviewReceiptScreen({
    super.key,
    this.imagePath,
    required this.ocrResult,
    this.existingTransaction,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final tx = widget.existingTransaction;
    final ocr = widget.ocrResult;

    _titleController = TextEditingController(
      text: tx?.title ?? ocr.merchant ?? 'Chi tiêu mua sắm',
    );

    final initialAmount = tx?.amount ?? ocr.amount ?? 0.0;
    _amountController = TextEditingController(
      text: initialAmount > 0 ? initialAmount.toStringAsFixed(0) : '',
    );

    _noteController = TextEditingController(
      text: tx?.note ?? (ocr.merchant != null ? 'Trích xuất tự động từ hoá đơn ${ocr.merchant}' : ''),
    );

    _selectedDate = tx?.date ?? ocr.date ?? DateTime.now();
    _selectedCategory = tx?.category ?? ocr.suggestedCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[,.\s]'), '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<ExpenseProvider>();
    final transaction = TransactionModel(
      id: widget.existingTransaction?.id,
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      receiptImagePath: widget.imagePath ?? widget.existingTransaction?.receiptImagePath,
      note: _noteController.text.trim(),
      rawOcrText: widget.ocrResult.rawText,
    );

    bool success;
    if (widget.existingTransaction != null) {
      success = await provider.updateTransaction(transaction);
    } else {
      success = await provider.addTransaction(transaction);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTransaction != null
                  ? 'Cập nhật giao dịch thành công!'
                  : 'Lưu hoá đơn thành công: ${CurrencyFormatter.formatVND(amount)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop back to home (pop scanner & review)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu giao dịch thất bại. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath ?? widget.existingTransaction?.receiptImagePath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          widget.existingTransaction != null ? 'Chỉnh Sửa Hoá Đơn' : 'Xác Nhận Hoá Đơn',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accent),
            onPressed: _isSaving ? null : _saveTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Thumbnail or OCR Confidence Status Card
              if (imagePath != null && File(imagePath).existsSync())
                Container(
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath), fit: BoxFit.cover),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Ảnh đã lưu cache',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Heuristic parsing banner
              if (widget.ocrResult.confidenceNotes != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.ocrResult.confidenceNotes!,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title / Merchant Name Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Tên cửa hàng / Nội dung chi',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.storefront, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // Total Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Tổng số tiền (VND)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.success),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final num = double.tryParse(val.replaceAll(RegExp(r'[,.\s]'), ''));
                  if (num == null || num <= 0) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ngày giao dịch',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          Text(
                            DateFormatter.format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selection
              const Text(
                'Phân loại danh mục:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                        const SizedBox(width: 6),
                        Text(cat.displayNameVi),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: AppColors.cardSurface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Ghi chú thêm',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Raw OCR Text Accordion (for inspection & debugging)
              if (widget.ocrResult.rawText.isNotEmpty)
                ExpansionTile(
                  title: const Text(
                    'Xem văn bản OCR gốc (Raw Text)',
                    style: TextStyle(color: AppColors.accent, fontSize: 13),
                  ),
                  leading: const Icon(Icons.document_scanner, color: AppColors.accent, size: 18),
                  collapsedBackgroundColor: AppColors.cardSurfaceLight.withOpacity(0.2),
                  backgroundColor: AppColors.cardSurfaceLight.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.ocrResult.rawText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  widget.existingTransaction != null ? 'Cập Nhật Giao Dịch' : 'Lưu Giao Dịch Vào Sổ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

