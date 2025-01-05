import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallettrack/models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalInstallmentsController =
      TextEditingController();
  DateTime? _selectedDate;
  bool _isInstallment = false;

  void _submitForm() {
    final String name = _nameController.text;
    final String amountText = _amountController.text;
    final String totalInstallmentsText = _totalInstallmentsController.text;
    final double? amount = double.tryParse(amountText);
    final int? totalInstallments =
        _isInstallment ? int.tryParse(totalInstallmentsText) : null;

    if (name.isEmpty ||
        amount == null ||
        _selectedDate == null ||
        (_isInstallment && totalInstallments == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields correctly!')),
      );
      return;
    }

    // Expense object creation
    final Expense newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      amount: amount,
      date: _selectedDate!,
      isInstallment: _isInstallment,
      totalInstallments: totalInstallments,
      paidInstallments: _isInstallment ? 0 : null,
      paidInstallmentsList: [],
    );

    // Debugging or further processing
    print(newExpense.toMap());

    // Optionally: Navigate back or reset the form
    Navigator.pop(context, newExpense);
  }

  void _presentDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Expense Name",
              ),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? "No Date Chosen!"
                        : "Picked Date: ${_selectedDate!.toLocal()}"
                            .split(' ')[0],
                  ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text("Choose Date"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _isInstallment,
                  onChanged: (value) {
                    setState(() {
                      _isInstallment = value!;
                    });
                  },
                ),
                const Text("Is this an installment?"),
              ],
            ),
            if (_isInstallment)
              TextField(
                controller: _totalInstallmentsController,
                decoration: const InputDecoration(
                  labelText: "Total Installments",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text("Add Expense"),
            ),
          ],
        ),
      ),
    );
  }
}
