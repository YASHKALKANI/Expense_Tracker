import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/currency_converter.dart';

class DownloadExpenses extends StatelessWidget {
  final List<Expense> expenses;
  final String selectedPeriod;

  const DownloadExpenses({
    super.key,
    required this.expenses,
    required this.selectedPeriod,
  });

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    return expenses.where((expense) {
      switch (selectedPeriod) {
        case 'Week':
          final difference = now.difference(expense.date);
          return difference.inDays <= 7;
        case 'Month':
          return expense.date.year == now.year && expense.date.month == now.month;
        case 'Year':
          return expense.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Future<double> _getTotalInInr(List<Expense> expenses) async {
    double total = 0;
    for (var expense in expenses) {
      total += await CurrencyConverter.convertToInr(expense.amount, expense.currency);
    }
    return total;
  }

  Future<double> _getTotalInUsd(List<Expense> expenses) async {
    double total = 0;
    for (var expense in expenses) {
      total += await CurrencyConverter.convertToUsd(expense.amount, expense.currency);
    }
    return total;
  }

  Future<void> _downloadExpenses(BuildContext context) async {
    final filteredExpenses = _getFilteredExpenses();
    if (filteredExpenses.isEmpty) {
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching latest exchange rates...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Calculate totals
    final totalInr = await _getTotalInInr(filteredExpenses);
    final totalUsd = await _getTotalInUsd(filteredExpenses);
    final rate = await CurrencyConverter.getExchangeRate();

    // Create CSV data
    List<List<dynamic>> rows = [];
    
    // Add header
    rows.add(['Expense Report - $selectedPeriod']);
    rows.add(['Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}']);
    rows.add(['Current Exchange Rate: 1 USD = ${rate.toStringAsFixed(2)} INR']);
    rows.add([]); // Empty row for spacing
    
    // Add totals
    rows.add(['Total Expenses']);
    rows.add(['In Rupees (₹)', 'In Dollars (\$)']);
    rows.add([totalInr.toStringAsFixed(2), totalUsd.toStringAsFixed(2)]);
    rows.add([]); // Empty row for spacing
    
    // Add column headers
    rows.add(['Date', 'Title', 'Category', 'Amount', 'Currency']);
    
    // Add expense details
    for (var expense in filteredExpenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.title,
        expense.category,
        expense.amount.toStringAsFixed(2),
        expense.currency,
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Get downloads directory
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      return;
    }

    final file = File('${directory.path}/expenses_${selectedPeriod.toLowerCase()}.csv');
    await file.writeAsString(csv);

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved to: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _downloadExpenses(context),
      icon: const Icon(Icons.download),
      label: Text('Download $selectedPeriod Records'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 