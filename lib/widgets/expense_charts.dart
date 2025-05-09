import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseCharts extends StatelessWidget {
  final List<Expense> expenses;
  final String selectedFilter;

  const ExpenseCharts({
    super.key,
    required this.expenses,
    required this.selectedFilter,
  });

  List<FlSpot> _getSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    switch (selectedFilter) {
      case 'Week':
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: 6 - i));
          final dayExpenses = expenses.where((expense) =>
              expense.date.year == date.year &&
              expense.date.month == date.month &&
              expense.date.day == date.day);
          final total = dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
          spots.add(FlSpot(i.toDouble(), total));
        }
        break;
      case 'Month':
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 0; i < daysInMonth; i++) {
          final date = DateTime(now.year, now.month, i + 1);
          final dayExpenses = expenses.where((expense) =>
              expense.date.year == date.year &&
              expense.date.month == date.month &&
              expense.date.day == date.day);
          final total = dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
          spots.add(FlSpot(i.toDouble(), total));
        }
        break;
      case 'Year':
        for (int i = 0; i < 12; i++) {
          final monthExpenses = expenses.where((expense) =>
              expense.date.year == now.year && expense.date.month == i + 1);
          final total = monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
          spots.add(FlSpot(i.toDouble(), total));
        }
        break;
    }

    return spots;
  }

  String _getXAxisTitle(int index) {
    switch (selectedFilter) {
      case 'Week':
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return DateFormat('E').format(date);
      case 'Month':
        return (index + 1).toString();
      case 'Year':
        return DateFormat('MMM').format(DateTime(2024, index + 1));
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();
    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No data available for the selected period',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= spots.length) return const Text('');
                  return Text(
                    _getXAxisTitle(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
          minY: 0,
          maxY: maxY * 1.2,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Theme.of(context).colorScheme.surface,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
} 