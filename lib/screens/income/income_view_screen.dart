import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/income.dart';

typedef RemoveCallBack = Function(Income income);

class IncomeViewScreen extends StatelessWidget {
  const IncomeViewScreen({
    super.key,
    required this.income,
    required this.removeCallback,
    required this.onPaymentReceived,
  });

  final Income income;
  final RemoveCallBack removeCallback;
  final Function(Income, int) onPaymentReceived;

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
    );
    return formatter.format(amount);
  }

  List<DateTime> _getRecurringDates() {
    if (!income.isRecurring) return [income.date];

    List<DateTime> dates = [];
    int months = 12;

    switch (income.recurringPeriod) {
      case 'weekly':
        for (var i = 0; i < months * 4; i++) {
          dates.add(income.date.add(Duration(days: i * 7)));
        }
      case 'monthly':
        for (var i = 0; i < months; i++) {
          dates.add(DateTime(
            income.date.year,
            income.date.month + i,
            income.date.day,
          ));
        }
      case 'yearly':
        for (var i = 0; i < 5; i++) {
          dates.add(DateTime(
            income.date.year + i,
            income.date.month,
            income.date.day,
          ));
        }
      default:
        dates = [income.date];
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getRecurringDates();

    return Scaffold(
      appBar: AppBar(
        title: Text(income.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              removeCallback(income);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(income.amount),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (income.isRecurring) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Recurring: ${income.recurringPeriod == 'monthly' ? 'Monthly' : income.recurringPeriod == 'weekly' ? 'Weekly' : 'Yearly'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dates.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isReceived = income.receivedPaymentsList.length > index &&
                    income.receivedPaymentsList[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calendar_today,
                    color: isReceived ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    DateFormat('MMMM d, y').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCurrency(income.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isReceived ? Colors.green : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isReceived ? Icons.check_circle : Icons.circle_outlined,
                        color: isReceived ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () => onPaymentReceived(income, index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
