import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/expense.dart';
import './add_expense_screen.dart';
import 'package:wallettrack/services/database_service.dart';
import 'package:wallettrack/screens/expense/expense_view_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wallettrack/widgets/logo.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({
    super.key,
    required this.database,
  });

  final AppDbService database;

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Expense> _expenses = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en_US', null).then((_) {
      loadExpenses();
    });
  }

  Future<void> loadExpenses() async {
    final expenses = await widget.database.getExpenses();
    if (mounted) {
      setState(() {
        _expenses = expenses;
      });
    }
  }

  Future<void> _onInstallmentPaid(Expense expense, int installmentIndex) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;

    final originalExpense = _expenses[index];
    List<bool> newPaidInstallments =
        List.from(originalExpense.paidInstallmentsList);

    if (originalExpense.isInstallment) {
      if (originalExpense.totalInstallments == null) return;

      // Calculate which installment we are in from the start date
      final startDate = originalExpense.date;
      final currentInstallmentIndex =
          (_currentMonth.year - startDate.year) * 12 +
              (_currentMonth.month - startDate.month);

      // Expand the list to total number of installments
      while (newPaidInstallments.length < originalExpense.totalInstallments!) {
        newPaidInstallments.add(false);
      }

      // Process only for current month
      if (currentInstallmentIndex >= 0 &&
          currentInstallmentIndex < originalExpense.totalInstallments!) {
        newPaidInstallments[currentInstallmentIndex] =
            !newPaidInstallments[currentInstallmentIndex];
      }
    } else {
      // For normal expense
      if (newPaidInstallments.isEmpty) {
        newPaidInstallments.add(false);
      }
      newPaidInstallments[0] = !newPaidInstallments[0];
    }

    final updatedExpense = originalExpense.copyWith(
      paidInstallmentsList: newPaidInstallments,
      paidInstallments: newPaidInstallments.where((paid) => paid).length,
    );

    await widget.database.updateExpense(updatedExpense);

    setState(() {
      _expenses[index] = updatedExpense;
    });
  }

  void _navigateToAddExpenseScreen(BuildContext context) async {
    final newExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (newExpense != null) {
      addExpense(newExpense);
    }
  }

  void addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
      widget.database.insertExpense(expense);
    });
  }

  Future<void> removeExpense(Expense expense) async {
    await widget.database.deleteExpense(expense.id);
    setState(() {
      _expenses.removeWhere((item) => item.id == expense.id);
    });
  }

  List<Expense> _filterExpensesByMonth() {
    List<Expense> filteredExpenses = [];

    for (var expense in _expenses) {
      if (expense.isInstallment && expense.totalInstallments != null) {
        final monthlyAmount = expense.amount / expense.totalInstallments!;
        DateTime installmentDate = expense.date;

        for (int i = 0; i < expense.totalInstallments!; i++) {
          if (installmentDate.year == _currentMonth.year &&
              installmentDate.month == _currentMonth.month) {
            // Calculate current installment index
            final currentInstallmentIndex = i;

            // There is an installment for this month
            filteredExpenses.add(
              Expense(
                id: expense.id,
                name: expense.name,
                amount: monthlyAmount,
                date: installmentDate,
                isInstallment: true,
                totalInstallments: expense.totalInstallments,
                paidInstallments:
                    expense.paidInstallmentsList.where((paid) => paid).length,
                paidInstallmentsList: expense.paidInstallmentsList,
                currentInstallmentIndex: currentInstallmentIndex,
              ),
            );
          }
          installmentDate = DateTime(
            installmentDate.year,
            installmentDate.month + 1,
            installmentDate.day,
          );
        }
      } else {
        if (expense.date.year == _currentMonth.year &&
            expense.date.month == _currentMonth.month) {
          filteredExpenses.add(expense);
        }
      }
    }

    return filteredExpenses;
  }

  double calculateTotal(List<Expense> expenses) {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM y', 'en_US').format(date);
  }

  Widget _buildExpensesList() {
    final filteredExpenses = _filterExpensesByMonth();
    return ListView.builder(
      itemCount: filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = filteredExpenses[index];

        // Calculate current installment index
        int currentInstallmentIndex = 0;
        if (expense.isInstallment) {
          currentInstallmentIndex =
              (_currentMonth.year - expense.date.year) * 12 +
                  (_currentMonth.month - expense.date.month);
        }

        return ListTile(
          title: Text(expense.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatCurrency(
                  expense.isInstallment && expense.totalInstallments != null
                      ? expense.amount / expense.totalInstallments!
                      : expense.amount)),
              if (expense.isInstallment &&
                  expense.totalInstallments != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Installment: ${expense.paidInstallments ?? 0}/${expense.totalInstallments}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.check_circle_outline,
              color: expense.isInstallment
                  ? (expense.paidInstallmentsList.length >
                              expense.currentInstallmentIndex &&
                          expense.paidInstallmentsList[
                              expense.currentInstallmentIndex]
                      ? Colors.green
                      : Colors.grey)
                  : (expense.paidInstallmentsList.isNotEmpty &&
                          expense.paidInstallmentsList[0]
                      ? Colors.green
                      : Colors.grey),
            ),
            onPressed: () =>
                _onInstallmentPaid(expense, currentInstallmentIndex),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseViewScreen(
                  expense: expense,
                  removeCallback: removeExpense,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _filterExpensesByMonth();
    final totalAmount = calculateTotal(filteredExpenses);

    return Scaffold(
      appBar: AppBar(
        leading: WalletLogo(),
        title: const Text("Expenses"),
        actions: [
          FilledButton(
            onPressed: () => _navigateToAddExpenseScreen(context),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _navigateToPreviousMonth,
                  icon: const Icon(Icons.arrow_left),
                ),
                Text(
                  _formatMonthYear(_currentMonth),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _navigateToNextMonth,
                  icon: const Icon(Icons.arrow_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(child: Text("No expenses found."))
                : _buildExpensesList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Expense This Month:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatCurrency(totalAmount),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
