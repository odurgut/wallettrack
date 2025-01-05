import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class CryptoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getCryptoRates() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final doc = await _firestore.collection('crypto_rates').doc(today).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['cryptos'] != null) {
          return data['cryptos'];
        }
      }

      final cryptos = await _fetchRatesFromAPI();
      await _firestore.collection('crypto_rates').doc(today).set({
        'cryptos': cryptos,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return cryptos;
    } catch (e) {
      print('Firestore error: $e');
      return await _fetchRatesFromAPI();
    }
  }

  Future<Map<String, dynamic>> _fetchRatesFromAPI() async {
    final response = await http.get(
      Uri.parse(APIConfig.cryptoUrl),
      headers: {
        'Authorization': 'apikey ${APIConfig.collectApiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = <String, dynamic>{};

      for (var item in data['result']) {
        result[item['code']] = {
          'name': item['name'],
          'rate': double.parse(item['price'].toString()),
        };
      }

      return result;
    } else {
      throw Exception('API request failed: ${response.statusCode}');
    }
  }
}
