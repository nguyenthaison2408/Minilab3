import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class CustomBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyData;

  const CustomBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<CustomBarChart> createState() => _CustomBarChartState();
}

class _CustomBarChartState extends State<CustomBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CustomBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
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
    if (widget.weeklyData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Chưa có dữ liệu tuần này',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxAmount = widget.weeklyData
        .map((e) => (e['amount'] as num).toDouble())
        .fold(0.0, max);
    final validMax = maxAmount > 0 ? maxAmount : 100000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tooltip or selection summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedIndex != null
                    ? DateFormat('EEEE, dd/MM', 'vi').format(
                        widget.weeklyData[_selectedIndex!]['date'] as DateTime,
                      )
                    : 'Chạm vào cột để xem chi tiết',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _selectedIndex != null
                    ? CurrencyFormatter.formatVND(
                        (widget.weeklyData[_selectedIndex!]['amount'] as num)
                            .toDouble(),
                      )
                    : '7 ngày gần nhất',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Chart Canvas with GestureDetector for Bar Hit-testing
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final width = constraints.maxWidth;
                  final count = widget.weeklyData.length;
                  final barWidth = width / count;
                  final tapIndex = (details.localPosition.dx / barWidth).floor();
                  if (tapIndex >= 0 && tapIndex < count) {
                    setState(() {
                      _selectedIndex = tapIndex;
                    });
                  }
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, 180),
                      painter: _BarChartPainter(
                        weeklyData: widget.weeklyData,
                        maxAmount: validMax,
                        progress: _animation.value,
                        selectedIndex: _selectedIndex,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weeklyData;
  final double maxAmount;
  final double progress;
  final int? selectedIndex;

  _BarChartPainter({
    required this.weeklyData,
    required this.maxAmount,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = weeklyData.length;
    if (count == 0) return;

    final bottomPadding = 30.0;
    final topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final slotWidth = size.width / count;
    final barWidth = min(slotWidth * 0.45, 24.0);

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Baseline
    final baseLinePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      baseLinePaint,
    );

    // Draw Bars and Labels
    for (int i = 0; i < count; i++) {
      final item = weeklyData[i];
      final amount = (item['amount'] as num).toDouble();
      final date = item['date'] as DateTime;
      final isSelected = selectedIndex == i;

      final normalizedHeight = (amount / maxAmount) * chartHeight * progress;
      final centerX = slotWidth * i + slotWidth / 2;
      final barLeft = centerX - barWidth / 2;
      final barRight = centerX + barWidth / 2;
      final barBottom = size.height - bottomPadding;
      final barTop = barBottom - max(normalizedHeight, 4.0); // minimum 4px for zero or tiny amounts

      final barRect = Rect.fromLTRB(barLeft, barTop, barRight, barBottom);
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      // Bar Paint with gradient
      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSelected
              ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
              : (amount > 0
                  ? [AppColors.primaryLight, AppColors.primary]
                  : [AppColors.cardSurfaceLight, AppColors.cardSurfaceLight.withOpacity(0.5)]),
        ).createShader(barRect);

      // Selected glow
      if (isSelected) {
        final glowPaint = Paint()
          ..color = AppColors.accent.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rrect, glowPaint);
      }

      canvas.drawRRect(rrect, barPaint);

      // Draw Day Label below bar (T2, T3, T4, T5, T6, T7, CN)
      final dayLabel = _getDayLabel(date);
      final textPainter = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }
  }

  String _getDayLabel(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.weeklyData != weeklyData;
  }
}

