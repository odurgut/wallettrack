import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getCurrencyRates() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc =
          await _firestore.collection('currency_rates').doc(today).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['rates'] != null) {
          return data['rates'];
        }
      }

      final rates = await _fetchRatesFromAPI();
      await _firestore.collection('currency_rates').doc(today).set({
        'rates': rates,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return rates;
    } catch (e) {
      print('Firestore error: $e');
      return await _fetchRatesFromAPI();
    }
  }

  Future<Map<String, dynamic>> _fetchRatesFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse(APIConfig.currencyUrl),
        headers: {
          'Authorization': 'apikey ${APIConfig.collectApiKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final result = data['result'] as List;

          final Map<String, dynamic> currencies = {};
          for (var currency in result) {
            if (currency['code'] != null && currency['selling'] != null) {
              currencies[currency['code']] = {
                'name': currency['name'] ?? currency['code'],
                'rate': double.tryParse(
                        currency['selling'].toString().replaceAll(',', '.')) ??
                    0.0,
                'code': currency['code'],
              };
            }
          }
          return currencies;
        }
      }
      throw Exception('API response is invalid format');
    } catch (e) {
      print('API error: $e');
      throw Exception('Failed to fetch currency rates from API: $e');
    }
  }
}
