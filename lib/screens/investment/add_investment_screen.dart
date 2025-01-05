import 'package:flutter/material.dart';
import '../../models/investment.dart';
import '../../services/currency_service.dart';
import '../../services/commodity_service.dart';
import '../../services/crypto_service.dart';
import 'package:intl/intl.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currencyService = CurrencyService();
  final _commodityService = CommodityService();
  final _cryptoService = CryptoService();
  String _selectedCategory = 'currency';
  String? _selectedCurrency;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _searchController = TextEditingController();
  Map<String, dynamic> _availableCurrencies = {};
  List<MapEntry<String, dynamic>> _filteredCurrencies = [];

  final Map<String, List<String>> _priorityItems = {
    'currency': ['TRY', 'USD', 'EUR', 'GBP'],
    'commodity': ['GOLD', 'SILVER', 'PLAT'],
    'crypto': ['BTC', 'ETH', 'USDT'],
  };

  @override
  void initState() {
    super.initState();
    _loadPrices();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    try {
      Map<String, dynamic> prices;

      switch (_selectedCategory) {
        case 'currency':
          prices = await _currencyService.getCurrencyRates();
        case 'commodity':
          prices = await _commodityService.getCommodityRates();
        case 'crypto':
          prices = await _cryptoService.getCryptoRates();
        default:
          prices = {};
      }

      setState(() {
        _availableCurrencies = prices;
        _filterCurrencies();
      });
    } catch (e) {
      print('Fiyatlar yüklenirken hata: $e');
    }
  }

  void _filterCurrencies() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      var entries = _availableCurrencies.entries.toList();
      var priorityList = _priorityItems[_selectedCategory] ?? [];

      var priorityEntries = entries
          .where((e) => priorityList.contains(e.key))
          .toList()
        ..sort((a, b) =>
            priorityList.indexOf(a.key).compareTo(priorityList.indexOf(b.key)));

      var otherEntries = entries
          .where((e) => !priorityList.contains(e.key))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (searchText.isNotEmpty) {
        priorityEntries = priorityEntries
            .where((e) =>
                e.key.toLowerCase().contains(searchText) ||
                e.value['name'].toString().toLowerCase().contains(searchText))
            .toList();

        otherEntries = otherEntries
            .where((e) =>
                e.key.toLowerCase().contains(searchText) ||
                e.value['name'].toString().toLowerCase().contains(searchText))
            .toList();
      }

      _filteredCurrencies = [...priorityEntries, ...otherEntries];
    });
  }

  Future<void> _updateCurrentPrice(String currencyCode) async {
    if (_availableCurrencies.containsKey(currencyCode)) {
      setState(() {
        _buyPriceController.text =
            _availableCurrencies[currencyCode]['rate'].toString();
      });
    }
  }

  Widget _buildAssetSelector() {
    switch (_selectedCategory) {
      case 'currency':
        return _buildCurrencySelector();
      case 'commodity':
        return _buildCommoditySelector();
      case 'crypto':
        return _buildCryptoSelector();
      default:
        return Container();
    }
  }

  Widget _buildCurrencySelector() {
    return ExpansionTile(
      title: Text(_selectedCurrency != null
          ? '${_selectedCurrency!} - ${_availableCurrencies[_selectedCurrency!]['name']}'
          : 'Currency Select'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Currency Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredCurrencies[index];
                    return ListTile(
                      title: Text('${entry.key} - ${entry.value['name']}'),
                      subtitle: Text(formatCurrency(entry.value['rate'])),
                      selected: _selectedCurrency == entry.key,
                      onTap: () => _selectAsset(entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommoditySelector() {
    return ExpansionTile(
      title: Text(_selectedCurrency != null
          ? '${_selectedCurrency!} - ${_availableCurrencies[_selectedCurrency!]['name']}'
          : 'Commodity Select'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Commodity Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredCurrencies[index];
                    return ListTile(
                      leading: const Icon(Icons.diamond),
                      title: Text(entry.value['name']),
                      subtitle:
                          Text('${formatCurrency(entry.value['rate'])} / gram'),
                      selected: _selectedCurrency == entry.key,
                      onTap: () => _selectAsset(entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoSelector() {
    return ExpansionTile(
      title: Text(_selectedCurrency != null
          ? '${_selectedCurrency!} - ${_availableCurrencies[_selectedCurrency!]['name']}'
          : 'Crypto Select'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Crypto Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredCurrencies[index];
                    return ListTile(
                      leading: const Icon(Icons.currency_bitcoin),
                      title: Text(entry.value['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key),
                          Text(formatCurrency(entry.value['rate'])),
                        ],
                      ),
                      selected: _selectedCurrency == entry.key,
                      onTap: () => _selectAsset(entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectAsset(String code) {
    setState(() {
      _selectedCurrency = code;
      _nameController.text = _availableCurrencies[code]['name'];
      _updateCurrentPrice(code);
    });
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Investment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: const [
                DropdownMenuItem(value: 'currency', child: Text('Currency')),
                DropdownMenuItem(value: 'commodity', child: Text('Commodity')),
                DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  _selectedCurrency = null;
                  _nameController.clear();
                  _loadPrices();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildAssetSelector(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyPriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a purchase price';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saveInvestment,
              child: const Text('Add Investment'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveInvestment() {
    if (_formKey.currentState!.validate()) {
      final investment = Investment(
        id: DateTime.now().millisecondsSinceEpoch,
        category: _selectedCategory,
        name: _selectedCurrency ?? '',
        amount: double.tryParse(_amountController.text) ?? 0,
        buyPrice: double.tryParse(_buyPriceController.text) ?? 0,
        currentPrice: double.tryParse(_buyPriceController.text) ?? 0,
        date: DateTime.now(),
      );
      Navigator.pop(context, investment);
    }
  }
}
