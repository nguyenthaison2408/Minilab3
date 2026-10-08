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
import '../scanner/review_receipt_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final cat = transaction.category;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Chi Tiết Giao Dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewReceiptScreen(
                    imagePath: transaction.receiptImagePath,
                    existingTransaction: transaction,
                    ocrResult: OcrResultModel(
                      merchant: transaction.title,
                      amount: transaction.amount,
                      date: transaction.date,
                      rawText: transaction.rawOcrText ?? '',
                      detectedLines: [],
                      suggestedCategory: transaction.category,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cat.color.withOpacity(0.2), AppColors.cardSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cat.color.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cat.color.withOpacity(0.2),
                    child: Icon(cat.icon, color: cat.color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    transaction.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatVND(transaction.amount),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cat.displayNameVi,
                      style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metadata items
            _buildDetailTile(
              icon: Icons.calendar_today,
              title: 'Thời gian',
              value: DateFormatter.formatWithTime(transaction.date),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              _buildDetailTile(
                icon: Icons.note_outlined,
                title: 'Ghi chú',
                value: transaction.note!,
              ),

            const SizedBox(height: 20),

            // Receipt Photo Preview if captured
            if (transaction.receiptImagePath != null) ...[
              const Text(
                'Ảnh Hoá Đơn Đính Kèm',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (File(transaction.receiptImagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(transaction.receiptImagePath!),
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ảnh hoá đơn không tồn tại trên thiết bị',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Raw OCR Data Accordion
            if (transaction.rawOcrText != null && transaction.rawOcrText!.isNotEmpty)
              ExpansionTile(
                title: const Text(
                  'Văn bản OCR nhận diện (Offline ML Kit)',
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
                leading: const Icon(Icons.document_scanner, color: AppColors.accent, size: 18),
                backgroundColor: AppColors.cardSurfaceLight.withOpacity(0.3),
                collapsedBackgroundColor: AppColors.cardSurfaceLight.withOpacity(0.3),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      transaction.rawOcrText!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Xoá giao dịch?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hành động này sẽ xoá vĩnh viễn khoản chi tiêu này khỏi sổ.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (transaction.id != null) {
                await context.read<ExpenseProvider>().deleteTransaction(transaction.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

