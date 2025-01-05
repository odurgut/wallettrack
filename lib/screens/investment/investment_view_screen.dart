import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment.dart';

typedef RemoveCallBack = Function(Investment investment);

class InvestmentViewScreen extends StatefulWidget {
  const InvestmentViewScreen({
    super.key,
    required this.investment,
    required this.removeCallback,
    required this.onPriceUpdated,
    required this.onAmountUpdated,
  });

  final Investment investment;
  final RemoveCallBack removeCallback;
  final Function(Investment, double) onPriceUpdated;
  final Function(Investment, double) onAmountUpdated;

  @override
  State<InvestmentViewScreen> createState() => _InvestmentViewScreenState();
}

class _InvestmentViewScreenState extends State<InvestmentViewScreen> {
  late Investment _investment;

  @override
  void initState() {
    super.initState();
    _investment = widget.investment;
  }

  void _updateAmount(double newAmount) {
    setState(() {
      _investment = _investment.copyWith(amount: newAmount);
    });
    widget.onAmountUpdated(_investment, newAmount);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);
  }

  double calculateProfit() {
    return (_investment.currentPrice - _investment.buyPrice) *
        _investment.amount;
  }

  double calculateProfitPercentage() {
    return ((_investment.currentPrice - _investment.buyPrice) /
            _investment.buyPrice) *
        100;
  }

  @override
  Widget build(BuildContext context) {
    final profit = calculateProfit();
    final profitPercentage = calculateProfitPercentage();

    return Scaffold(
      appBar: AppBar(
        title: Text(_investment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Investment'),
                  content: const Text(
                      'Are you sure you want to delete this investment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.removeCallback(_investment);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
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
                  Row(
                    children: [
                      Icon(
                        _investment.category == 'currency'
                            ? Icons.currency_exchange
                            : _investment.category == 'commodity'
                                ? Icons.diamond
                                : Icons.currency_bitcoin,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _investment.category[0].toUpperCase() +
                            _investment.category.substring(1),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    'Amount',
                    '${_investment.amount} units',
                    onEdit: () => _showUpdateAmountDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Purchase Price',
                    formatCurrency(_investment.buyPrice),
                    onEdit: () => _showUpdatePriceDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Current Price',
                    formatCurrency(_investment.currentPrice),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Total Value',
                    formatCurrency(
                        _investment.amount * _investment.currentPrice),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Purchase Date',
                    DateFormat('MMMM d, y').format(_investment.date),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: profit >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit/Loss',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatCurrency(profit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        '${profitPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Row(
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  padding: const EdgeInsets.only(right: 8),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  color: Colors.grey[600],
                ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdatePriceDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _investment.buyPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Purchase Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Purchase Price',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                setState(() {
                  _investment = _investment.copyWith(buyPrice: newPrice);
                });
                widget.onPriceUpdated(_investment, newPrice);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _investment.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Miktar Güncelle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Yeni Miktar',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final newAmount = double.tryParse(controller.text);
              if (newAmount != null) {
                _updateAmount(newAmount);
                Navigator.pop(context);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}
