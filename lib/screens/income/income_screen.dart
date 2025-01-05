import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/income.dart';
import 'package:wallettrack/screens/income/add_income_screen.dart';
import 'package:wallettrack/services/database_service.dart';
import 'package:wallettrack/screens/income/income_view_screen.dart';
import 'package:wallettrack/widgets/logo.dart';

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({
    super.key,
    required this.database,
  });

  final AppDbService database;

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  List<Income> _incomes = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    final incomes = await widget.database.getIncomes();
    if (mounted) {
      setState(() {
        _incomes = incomes;
      });
    }
  }

  Future<void> _onPaymentReceived(Income income, int paymentIndex) async {
    final index = _incomes.indexWhere((e) => e.id == income.id);
    if (index == -1) return;

    List<bool> newReceivedPayments = List.from(income.receivedPaymentsList);

    while (newReceivedPayments.length <= paymentIndex) {
      newReceivedPayments.add(false);
    }

    newReceivedPayments[paymentIndex] = !newReceivedPayments[paymentIndex];

    final updatedIncome = income.copyWith(
      receivedPaymentsList: newReceivedPayments,
    );

    await widget.database.updateIncome(updatedIncome);

    setState(() {
      _incomes[index] = updatedIncome;
    });
  }

  void _navigateToAddIncomeScreen(BuildContext context) async {
    final newIncome = await Navigator.push<Income>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    );

    if (newIncome != null) {
      addIncome(newIncome);
    }
  }

  void addIncome(Income income) {
    setState(() {
      _incomes.add(income);
      widget.database.insertIncome(income);
    });
  }

  Future<void> removeIncome(Income income) async {
    await widget.database.deleteIncome(income.id);
    setState(() {
      _incomes.removeWhere((item) => item.id == income.id);
    });
  }

  List<Income> _filterIncomesByMonth() {
    List<Income> filteredIncomes = [];

    for (var income in _incomes) {
      if (income.isRecurring) {
        // For recurring incomes, check
        bool shouldShow = false;
        DateTime checkDate = income.date;

        switch (income.recurringPeriod) {
          case 'weekly':
            // For weekly recurring income, check all weeks in the month
            while (checkDate.month == income.date.month) {
              if (checkDate.year == _currentMonth.year &&
                  checkDate.month == _currentMonth.month) {
                shouldShow = true;
                break;
              }
              checkDate = checkDate.add(const Duration(days: 7));
            }

          case 'monthly':
            // For monthly recurring income, check
            shouldShow = checkDate.isBefore(_currentMonth) ||
                (checkDate.year == _currentMonth.year &&
                    checkDate.month == _currentMonth.month);

          case 'yearly':
            // For yearly recurring income, check
            shouldShow = checkDate.month == _currentMonth.month &&
                checkDate.isBefore(_currentMonth);
        }

        if (shouldShow) {
          // Update the date but keep other properties
          filteredIncomes.add(income.copyWith(
            date: DateTime(
              _currentMonth.year,
              _currentMonth.month,
              income.date.day,
            ),
          ));
        }
      } else {
        // For non-recurring incomes, use current check
        if (income.date.year == _currentMonth.year &&
            income.date.month == _currentMonth.month) {
          filteredIncomes.add(income);
        }
      }
    }

    return filteredIncomes;
  }

  double calculateTotal(List<Income> incomes) {
    return incomes.fold(0, (sum, income) => sum + income.amount);
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
    return DateFormat('MMMM y').format(date);
  }

  Widget _buildIncomesList() {
    final filteredIncomes = _filterIncomesByMonth();
    return ListView.builder(
      itemCount: filteredIncomes.length,
      itemBuilder: (context, index) {
        final income = filteredIncomes[index];
        return ListTile(
          title: Text(income.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatCurrency(income.amount)),
              if (income.isRecurring) ...[
                const SizedBox(height: 4),
                Text(
                  'Repeat: ${income.recurringPeriod == 'monthly' ? 'Monthly' : income.recurringPeriod == 'weekly' ? 'Weekly' : 'Yearly'}',
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
              color: income.receivedPaymentsList.isNotEmpty &&
                      income.receivedPaymentsList[0]
                  ? Colors.green
                  : Colors.grey,
            ),
            onPressed: () => _onPaymentReceived(income, 0),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncomeViewScreen(
                  income: income,
                  removeCallback: removeIncome,
                  onPaymentReceived: _onPaymentReceived,
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
    final filteredIncomes = _filterIncomesByMonth();
    final totalAmount = calculateTotal(filteredIncomes);

    return Scaffold(
      appBar: AppBar(
        leading: WalletLogo(),
        title: const Text("Incomes"),
        actions: [
          FilledButton(
            onPressed: () => _navigateToAddIncomeScreen(context),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Month selector
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
          // ListView
          Expanded(
            child: filteredIncomes.isEmpty
                ? const Center(
                    child: Text("No incomes found."),
                  )
                : _buildIncomesList(),
          ),
          // Total income box
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
                      "Income This Month:",
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
