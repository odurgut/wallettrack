import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/expense.dart';

typedef RemoveCallBack = Function(Expense expense);

class ExpenseViewScreen extends StatelessWidget {
  const ExpenseViewScreen(
      {super.key, required this.expense, required this.removeCallback});

  final Expense expense;
  final RemoveCallBack removeCallback;

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final monthlyAmount =
        expense.isInstallment && expense.totalInstallments != null
            ? expense.amount / expense.totalInstallments!
            : expense.amount;

    return Scaffold(
      appBar: AppBar(
        title: Text(expense.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              removeCallback(expense);
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
            // Expense Details Section
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
                    formatCurrency(expense.amount),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (expense.isInstallment &&
                      expense.totalInstallments != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Monthly: ${formatCurrency(monthlyAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Installment Progress: ${expense.paidInstallments ?? 0} / ${expense.totalInstallments}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment History Section
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expense.totalInstallments ?? 1,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final date = DateTime(
                  expense.date.year,
                  expense.date.month + index,
                  expense.date.day,
                );

                final isPaid = expense.paidInstallmentsList.length > index &&
                    expense.paidInstallmentsList[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calendar_today,
                    color: isPaid ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    DateFormat('MMMM d, y').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCurrency(monthlyAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isPaid ? Icons.check_circle : Icons.circle_outlined,
                        color: isPaid ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
