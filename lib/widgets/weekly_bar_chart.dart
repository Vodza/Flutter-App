import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class WeeklyBarChart extends StatefulWidget {
  final List<double> weeklyAmounts; // 7 ngày từ 6 ngày trước đến hôm nay

  const WeeklyBarChart({
    super.key,
    required this.weeklyAmounts,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyAmounts != widget.weeklyAmounts) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _generateDayLabels() {
    final now = DateTime.now();
    final List<String> labels = [];
    final weekDayMap = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      if (i == 6) {
        labels.add('Hôm nay');
      } else {
        labels.add(weekDayMap[date.weekday] ?? 'T${date.weekday}');
      }
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = _generateDayLabels();
    final maxAmount = widget.weeklyAmounts.fold<double>(0.0, (m, val) => math.max(m, val));
    final double safeMax = maxAmount > 0 ? maxAmount : 100000.0;
    final currencyFormatter = NumberFormat.compact(locale: 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiêu tuần này',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Cao nhất: ${currencyFormatter.format(maxAmount)}₫',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BarChartPainter(
                    amounts: widget.weeklyAmounts,
                    labels: dayLabels,
                    maxAmount: safeMax,
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> amounts;
  final List<String> labels;
  final double maxAmount;
  final double progress;

  _BarChartPainter({
    required this.amounts,
    required this.labels,
    required this.maxAmount,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    final chartHeight = size.height - bottomLabelHeight;
    final count = amounts.length;
    final slotWidth = size.width / count;
    final barWidth = slotWidth * 0.42;

    // Vẽ đường kẻ mờ mốc 50% và 100%
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, chartHeight / 2), Offset(size.width, chartHeight / 2), gridPaint);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);

    for (int i = 0; i < count; i++) {
      final centerX = (i * slotWidth) + (slotWidth / 2);
      final rawAmount = amounts[i];
      final ratio = math.min(1.0, rawAmount / maxAmount);
      final barHeight = chartHeight * ratio * progress;

      final left = centerX - (barWidth / 2);
      final top = chartHeight - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      // Nền mờ cho mỗi cột để tạo chiều sâu UI
      final barBgRect = Rect.fromLTWH(left, 0, barWidth, chartHeight);
      final bgPaint = Paint()..color = Colors.grey.shade50;
      canvas.drawRRect(
        RRect.fromRectAndRadius(barBgRect, const Radius.circular(6)),
        bgPaint,
      );

      // Cột chi tiêu thực tế (Màu gradient xanh biển hoặc nổi bật nếu là ngày hiện tại)
      final isToday = (i == count - 1);
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isToday
              ? [const Color(0xFF2563EB), const Color(0xFF60A5FA)]
              : [const Color(0xFF64748B), const Color(0xFF94A3B8)],
        ).createShader(rect);

      if (barHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          barPaint,
        );
      }

      // Vẽ nhãn ngày ở phía dưới
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isToday ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          fontSize: isToday ? 11 : 10,
          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.amounts != amounts ||
        oldDelegate.maxAmount != maxAmount;
  }
}
