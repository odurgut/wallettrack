import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/income.dart';
import 'package:wallettrack/screens/income/income_view_screen.dart';

class IncomeItem extends StatelessWidget {
  const IncomeItem({
    super.key,
    required this.income,
    required this.removeCallback,
    required this.onPaymentReceived,
  });

  final Income income;
  final Function(Income) removeCallback;
  final Function(Income, int) onPaymentReceived;

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
      title: Text(income.name),
      subtitle: Text(formatCurrency(income.amount)),
      trailing: IconButton(
        icon: Icon(
          Icons.check_circle_outline,
          color: income.receivedPaymentsList.isNotEmpty &&
                  income.receivedPaymentsList[0]
              ? Colors.green
              : Colors.grey,
        ),
        onPressed: () => onPaymentReceived(income, 0),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomeViewScreen(
              income: income,
              removeCallback: removeCallback,
              onPaymentReceived: onPaymentReceived,
            ),
          ),
        );
      },
    );
  }
}
