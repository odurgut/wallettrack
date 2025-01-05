import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/investment.dart';
import 'package:intl/intl.dart';
import 'investment_view_screen.dart';
import 'dart:async';
import '../../services/currency_service.dart';
import 'add_investment_screen.dart';
import '../../services/commodity_service.dart';
import '../../services/crypto_service.dart';
import '../../widgets/logo.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({
    super.key,
    required this.database,
  });

  final AppDbService database;

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final CommodityService _commodityService = CommodityService();
  final CryptoService _cryptoService = CryptoService();
  Timer? _rateUpdateTimer;
  List<Investment> _investments = [];

  @override
  void initState() {
    super.initState();
    _loadInvestments();
    _loadAllRates();
    _rateUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadAllRates(),
    );
  }

  @override
  void dispose() {
    _rateUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvestments() async {
    final investments = await widget.database.getInvestments();
    setState(() {
      _investments = investments;
    });
  }

  Future<void> _loadAllRates() async {
    await _loadCurrencyRates();
    await _loadCommodityRates();
    await _loadCryptoRates();
  }

  Future<void> _loadCurrencyRates() async {
    try {
      final rates = await _currencyService.getCurrencyRates();
      _updateInvestmentRates('currency', rates);
    } catch (e) {
      _handleRateError(e);
    }
  }

  Future<void> _loadCommodityRates() async {
    try {
      final rates = await _commodityService.getCommodityRates();
      _updateInvestmentRates('commodity', rates);
    } catch (e) {
      _handleRateError(e);
    }
  }

  Future<void> _loadCryptoRates() async {
    try {
      final rates = await _cryptoService.getCryptoRates();
      _updateInvestmentRates('crypto', rates);
    } catch (e) {
      _handleRateError(e);
    }
  }

  void _updateInvestmentRates(String category, Map<String, dynamic> rates) {
    if (mounted) {
      setState(() {
        for (var investment in _investments) {
          if (investment.category == category) {
            final code = investment.name.split(' ').first.toUpperCase();
            if (rates.containsKey(code)) {
              _updateInvestmentPrice(
                  investment, (rates[code]['rate'] as num).toDouble());
            }
          }
        }
      });
    }
  }

  void _handleRateError(dynamic error) {
    if (mounted) {
      print('Fiyatlar güncellenirken hata oluştu: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fiyatlar güncellenirken hata oluştu: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategoryList(String category) {
    final categoryInvestments = _investments
        .where((investment) => investment.category == category)
        .toList();

    final totalValue = categoryInvestments.fold<double>(
      0,
      (sum, investment) => sum + (investment.amount * investment.currentPrice),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: categoryInvestments.length,
            itemBuilder: (context, index) {
              final investment = categoryInvestments[index];
              final investmentValue =
                  investment.amount * investment.currentPrice;

              return ListTile(
                title: Text(investment.name),
                subtitle: Text(
                    '${investment.amount} units (${formatCurrency(investmentValue)})'),
                trailing: Text(formatCurrency(investment.currentPrice)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvestmentViewScreen(
                      investment: investment,
                      removeCallback: _removeInvestment,
                      onPriceUpdated: _updateInvestmentPrice,
                      onAmountUpdated: _updateInvestmentAmount,
                    ),
                  ),
                ),
              );
            },
          ),
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
                  Text(
                    'Total Value:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatCurrency(totalValue),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);
  }

  Future<void> _removeInvestment(Investment investment) async {
    await widget.database.deleteInvestment(investment.id!);
    await _loadInvestments();
  }

  Future<void> _updateInvestmentPrice(
      Investment investment, double newPrice) async {
    final updatedInvestment = Investment(
      id: investment.id,
      category: investment.category,
      name: investment.name,
      amount: investment.amount,
      buyPrice: investment.buyPrice,
      currentPrice: newPrice,
      date: investment.date,
    );

    await widget.database.updateInvestment(updatedInvestment);
    await _loadInvestments();
  }

  Future<void> _updateInvestmentAmount(
      Investment investment, double newAmount) async {
    final updatedInvestment = Investment(
      id: investment.id,
      category: investment.category,
      name: investment.name,
      amount: newAmount,
      buyPrice: investment.buyPrice,
      currentPrice: investment.currentPrice,
      date: investment.date,
    );

    await widget.database.updateInvestment(updatedInvestment);
    await _loadInvestments();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: WalletLogo(),
          title: const Text('Investments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Currency'),
              Tab(text: 'Commodity'),
              Tab(text: 'Crypto'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddInvestmentScreen(),
                  ),
                );
                if (result != null && result is Investment) {
                  await widget.database.insertInvestment(result);
                  await _loadInvestments();
                }
              },
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: TabBarView(
          children: [
            _buildCategoryList('currency'),
            _buildCategoryList('commodity'),
            _buildCategoryList('crypto'),
          ],
        ),
      ),
    );
  }
}
