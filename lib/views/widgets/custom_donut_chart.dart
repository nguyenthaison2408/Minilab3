import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class CustomDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
  });

  @override
  State<CustomDonutChart> createState() => _CustomDonutChartState();
}

class _CustomDonutChartState extends State<CustomDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CustomDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validTotal = widget.totalAmount > 0 ? widget.totalAmount : 1.0;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _DonutChartPainter(
                      data: widget.data,
                      total: validTotal,
                      progress: _animation.value,
                      selectedCategory: _selectedCategory,
                    ),
                  ),
                  // Center Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory != null
                            ? _selectedCategory!.displayNameVi
                            : 'Tổng chi tiêu',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategory != null
                            ? CurrencyFormatter.formatCompact(widget.data[_selectedCategory] ?? 0)
                            : CurrencyFormatter.formatCompact(widget.totalAmount),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCategory != null && widget.totalAmount > 0)
                        Text(
                          '${(((widget.data[_selectedCategory] ?? 0) / widget.totalAmount) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _selectedCategory!.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Interactive Category Chips / Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: ExpenseCategory.values.map((cat) {
            final catAmount = widget.data[cat] ?? 0.0;
            final percent = widget.totalAmount > 0
                ? (catAmount / widget.totalAmount * 100).toStringAsFixed(1)
                : '0.0';
            final isSelected = _selectedCategory == cat;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withOpacity(0.2)
                      : AppColors.cardSurfaceLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cat.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.displayNameVi,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: cat.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double total;
  final double progress;
  final ExpenseCategory? selectedCategory;

  _DonutChartPainter({
    required this.data,
    required this.total,
    required this.progress,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 26.0;
    const double gapAngle = 0.04; // small gap between slices for modern aesthetic

    // Draw background track when total is 0
    if (total <= 0) {
      final bgPaint = Paint()
        ..color = AppColors.cardSurfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);
      return;
    }

    double startAngle = -pi / 2;

    for (final entry in data.entries) {
      final category = entry.key;
      final amount = entry.value;
      if (amount <= 0) continue;

      final sliceSweep = (amount / total) * 2 * pi * progress;
      if (sliceSweep <= 0) continue;

      final isSelected = selectedCategory == category;
      final currentStroke = isSelected ? strokeWidth + 6 : strokeWidth;
      final currentRadius = isSelected ? radius - strokeWidth / 2 + 2 : radius - strokeWidth / 2;

      final paint = Paint()
        ..color = isSelected ? category.color : category.color.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.round;

      // Draw shadow for selected slice
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = category.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: currentRadius),
          startAngle + gapAngle / 2,
          max(0, sliceSweep - gapAngle),
          false,
          shadowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle + gapAngle / 2,
        max(0, sliceSweep - gapAngle),
        false,
        paint,
      );

      startAngle += sliceSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.total != total;
  }
}

