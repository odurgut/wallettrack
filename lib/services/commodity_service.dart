import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class CommodityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getCommodityRates() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc =
          await _firestore.collection('commodity_rates').doc(today).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['commodities'] != null) {
          return data['commodities'];
        }
      }

      final commodities = await _fetchAllRatesFromAPI();
      await _firestore.collection('commodity_rates').doc(today).set({
        'commodities': commodities,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return commodities;
    } catch (e) {
      print('Firestore error: $e');
      return await _fetchAllRatesFromAPI();
    }
  }

  Future<Map<String, dynamic>> _fetchAllRatesFromAPI() async {
    try {
      final Map<String, dynamic> result = {};

      // General commodity prices
      final commodityData = await _fetchCommodityData();
      result.addAll(commodityData);

      // Gold prices
      final goldData = await _fetchGoldData();
      result.addAll(goldData);

      // Silver prices
      final silverData = await _fetchSilverData();
      result.addAll(silverData);

      return result;
    } catch (e) {
      print('API error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchCommodityData() async {
    final response = await http.get(
      Uri.parse(APIConfig.commodityUrl),
      headers: {
        'Authorization': 'apikey ${APIConfig.collectApiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = <String, dynamic>{};

      for (var item in data['result']) {
        final code = item['name'].toString();
        result[code] = {
          'name': item['text'],
          'rate': double.tryParse(item['selling'].toString()) ?? 0.0,
        };
      }
      return result;
    }
    throw Exception('Commodity API response is invalid');
  }

  Future<Map<String, dynamic>> _fetchGoldData() async {
    final response = await http.get(
      Uri.parse(APIConfig.goldUrl),
      headers: {
        'Authorization': 'apikey ${APIConfig.collectApiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = <String, dynamic>{};

      for (var item in data['result']) {
        if (item['name'] == 'Gram Altın') {
          result['GOLD'] = {
            'name': 'Gold',
            'rate': double.tryParse(item['selling'].toString()) ?? 0.0,
          };
          break;
        }
      }
      return result;
    }
    throw Exception('Gold API response is invalid');
  }

  Future<Map<String, dynamic>> _fetchSilverData() async {
    final response = await http.get(
      Uri.parse(APIConfig.silverUrl),
      headers: {
        'Authorization': 'apikey ${APIConfig.collectApiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = <String, dynamic>{};

      if (data['result'] != null && data['result']['selling'] != null) {
        result['SILVER'] = {
          'name': 'Silver',
          'rate': double.tryParse(data['result']['selling'].toString()) ?? 0.0,
        };
      }
      return result;
    }
    throw Exception('Silver API response is invalid');
  }
}
