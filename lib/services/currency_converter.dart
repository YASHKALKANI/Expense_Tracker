import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConverter {
  static double _cachedRate = 83.0; // Default fallback rate
  static DateTime _lastUpdate = DateTime.now().subtract(const Duration(hours: 1));

  static Future<double> getExchangeRate() async {
    // Check if we need to update the rate (update every hour)
    if (DateTime.now().difference(_lastUpdate).inHours >= 1) {
      try {
        final response = await http.get(Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/USD',
        ));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _cachedRate = data['rates']['INR'].toDouble();
          _lastUpdate = DateTime.now();
        }
      } catch (e) {
        // If API call fails, use the cached rate
        print('Error fetching exchange rate: $e');
      }
    }
    return _cachedRate;
  }

  static Future<double> convertToInr(double amount, String fromCurrency) async {
    final rate = await getExchangeRate();
    if (fromCurrency == '\$') {
      return amount * rate;
    }
    return amount;
  }

  static Future<double> convertToUsd(double amount, String fromCurrency) async {
    final rate = await getExchangeRate();
    if (fromCurrency == '₹') {
      return amount / rate;
    }
    return amount;
  }
} 