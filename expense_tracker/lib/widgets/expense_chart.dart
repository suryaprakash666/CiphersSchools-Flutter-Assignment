import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'dart:math';

class ExpenseChart extends StatelessWidget {
  final List<Transaction> expenses;
  final double totalExpense;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    // Group expenses by category
    final Map<String, double> categoryExpenses = {};
    for (var tx in expenses) {
      if (tx.type == 'expense') {
        categoryExpenses.update(
          tx.category,
          (value) => value + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }

    // Assign colors to categories
    final Map<String, Color> categoryColors = {};
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.orange,
      Colors.indigo,
    ];

    int colorIndex = 0;
    for (var category in categoryExpenses.keys) {
      categoryColors[category] = colors[colorIndex % colors.length];
      colorIndex++;
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Expense Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child:
              categoryExpenses.isEmpty
                  ? const Center(child: Text('No expenses to display'))
                  : Row(
                    children: [
                      // Pie chart
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: CustomPaint(
                            painter: PieChartPainter(
                              categoryExpenses: categoryExpenses,
                              categoryColors: categoryColors,
                              totalExpense: totalExpense,
                            ),
                            child: Container(),
                          ),
                        ),
                      ),
                      // Legend
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                categoryExpenses.keys.map((category) {
                                  final percentage =
                                      (categoryExpenses[category]! /
                                          totalExpense) *
                                      100;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          color: categoryColors[category],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$category (${percentage.toStringAsFixed(1)}%)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> categoryExpenses;
  final Map<String, Color> categoryColors;
  final double totalExpense;

  PieChartPainter({
    required this.categoryExpenses,
    required this.categoryColors,
    required this.totalExpense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    double startAngle = 0;

    for (var category in categoryExpenses.keys) {
      final sweepAngle = (categoryExpenses[category]! / totalExpense) * 2 * pi;

      final paint =
          Paint()
            ..color = categoryColors[category]!
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
