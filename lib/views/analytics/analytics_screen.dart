import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/expense_provider.dart';
import '../widgets/custom_bar_chart.dart';
import '../widgets/custom_donut_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final totalExpense = provider.totalExpense;
        final categoryExpenses = provider.categoryExpenses;
        final weeklyExpenses = provider.weeklyExpenses;

        // Find highest spending category
        ExpenseCategory? highestCategory;
        double maxCategoryAmount = 0.0;
        categoryExpenses.forEach((cat, amt) {
          if (amt > maxCategoryAmount) {
            maxCategoryAmount = amt;
            highestCategory = cat;
          }
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
            title: const Text(
              'Thống Kê Chi Tiêu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.cardSurface,
                  onRefresh: () => provider.loadAllData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPI Metric Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Tổng đã chi',
                                value: CurrencyFormatter.formatCompact(totalExpense),
                                icon: Icons.account_balance_wallet,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Chi nhiều nhất',
                                value: highestCategory?.displayNameVi ?? 'Chưa có',
                                icon: highestCategory?.icon ?? Icons.category,
                                color: highestCategory?.color ?? AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Animated Category Distribution Donut Chart (CustomPainter)
                        _buildSectionCard(
                          title: 'Phân Bổ Danh Mục (Donut Canvas)',
                          subtitle: 'CustomPainter thuần không dùng thư viện ngoài',
                          child: CustomDonutChart(
                            data: categoryExpenses,
                            totalAmount: totalExpense,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Animated Weekly Spending Bar Chart (CustomPainter)
                        _buildSectionCard(
                          title: 'Chi Tiêu 7 Ngày Gần Nhất (Bar Canvas)',
                          subtitle: 'Chạm vào cột để xem số liệu chi tiết từng ngày',
                          child: CustomBarChart(
                            weeklyData: weeklyExpenses,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Detailed Category Breakdown List
                        _buildSectionCard(
                          title: 'Chi Tiết Theo Danh Mục',
                          subtitle: 'Tỉ lệ phần trăm trên tổng ngân sách',
                          child: Column(
                            children: ExpenseCategory.values.map((cat) {
                              final amt = categoryExpenses[cat] ?? 0.0;
                              final ratio = totalExpense > 0 ? (amt / totalExpense) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: cat.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(cat.icon, color: cat.color, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            cat.displayNameVi,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatVND(amt),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        backgroundColor: AppColors.cardSurfaceLight.withOpacity(0.5),
                                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

