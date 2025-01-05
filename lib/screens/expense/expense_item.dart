import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/expense.dart';
import 'package:wallettrack/screens/expense/expense_view_screen.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem({
    super.key,
    required this.expense,
    required this.originalExpense,
    required this.removeCallBack,
    required this.onInstallmentPaid,
  });

  final Expense expense;
  final Expense originalExpense;
  final Function(Expense) removeCallBack;
  final Function(Expense, int) onInstallmentPaid;

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.name),
      subtitle: Text(formatCurrency(expense.amount)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expense.isInstallment)
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: expense.paidInstallmentsList.isNotEmpty &&
                        expense.paidInstallmentsList[0]
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () => onInstallmentPaid(expense, 0),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => removeCallBack(expense),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseViewScreen(
              expense: expense,
              removeCallback: removeCallBack,
            ),
          ),
        );
      },
    );
  }
}
