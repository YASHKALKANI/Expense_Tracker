import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../widgets/expense_list.dart';
import '../widgets/add_expense.dart';
import '../widgets/expense_charts.dart';
import '../widgets/download_expenses.dart';
import '../services/currency_converter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [];
  String _selectedFilter = 'All';
  String _selectedCurrency = '₹';
  String _selectedPeriod = 'Total';
  double _inrTotal = 0;
  double _usdTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList('expenses') ?? [];
    
    setState(() {
      _expenses.clear();
      for (var expenseJson in expensesJson) {
        final expenseMap = json.decode(expenseJson);
        _expenses.add(Expense.fromJson(expenseMap));
      }
      _updateTotals();
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = _expenses.map((expense) => json.encode(expense.toJson())).toList();
    await prefs.setStringList('expenses', expensesJson);
  }

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
      _updateTotals();
      _saveExpenses();
    });
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
      _updateTotals();
      _saveExpenses();
    });
  }

  Future<void> _updateTotals() async {
    setState(() {
      _isLoading = true;
    });

    final inrTotal = await _getPeriodTotal(_selectedPeriod, convertToInr: true);
    final usdTotal = await _getPeriodTotal(_selectedPeriod, convertToInr: false);

    setState(() {
      _inrTotal = inrTotal;
      _usdTotal = usdTotal;
      _isLoading = false;
    });
  }

  void _showAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExpense(
        onAddExpense: _addExpense,
        selectedCurrency: _selectedCurrency,
      ),
    );
  }

  Future<double> _getPeriodTotal(String period, {bool convertToInr = true}) async {
    final now = DateTime.now();
    final filteredExpenses = _expenses.where((expense) {
      switch (period) {
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
    });

    double total = 0;
    for (var expense in filteredExpenses) {
      if (convertToInr) {
        total += await CurrencyConverter.convertToInr(expense.amount, expense.currency);
      } else {
        total += await CurrencyConverter.convertToUsd(expense.amount, expense.currency);
      }
    }
    return total;
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    dropdownColor: Theme.of(context).colorScheme.primary,
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: ['Total', 'Week', 'Month', 'Year'].map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                        _updateTotals();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    dropdownColor: Theme.of(context).colorScheme.primary,
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: ['₹', '\$'].map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Text(
                      '${_selectedCurrency}${_selectedCurrency == '₹' ? _inrTotal : _usdTotal}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_isLoading)
                Text(
                  '≈ ${_selectedCurrency == '₹' ? '\$${_usdTotal.toStringAsFixed(2)}' : '₹${_inrTotal.toStringAsFixed(2)}'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              const SizedBox(height: 16),
              DownloadExpenses(
                expenses: _expenses,
                selectedPeriod: _selectedPeriod,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Expense Tracker',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTotalCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['All', 'Week', 'Month', 'Year'].map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_selectedFilter != 'All')
            SliverToBoxAdapter(
              child: ExpenseCharts(
                expenses: _expenses,
                selectedFilter: _selectedFilter,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Recent Expenses',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ExpenseList(
              expenses: _expenses,
              onDeleteExpense: _deleteExpense,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
} 