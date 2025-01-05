import 'package:flutter/material.dart';
import 'package:wallettrack/models/income.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _amount = 0;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String _recurringPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter income name',
              ),
              onChanged: (value) => _name = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _amount = double.tryParse(value) ?? 0,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Recurring Income'),
              trailing: Switch(
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurringPeriod,
                decoration: const InputDecoration(
                  labelText: 'Recurring Period',
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurringPeriod = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final income = Income(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: _name,
                    amount: _amount,
                    date: _date,
                    isRecurring: _isRecurring,
                    recurringPeriod: _recurringPeriod,
                    receivedPaymentsList: [false],
                  );
                  Navigator.pop(context, income);
                }
              },
              child: const Text('Add Income'),
            ),
          ],
        ),
      ),
    );
  }
}
