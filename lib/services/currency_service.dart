import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _cachedRatesKey = 'cached_exchange_rates';
  static const String _lastUpdatedKey = 'rates_last_updated_timestamp';

  // API URL for live rates
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  // Fallback rates if user has never opened the app with internet before
  static Map<String, double> defaultRates = {
    'USD': 1.0,
    'EUR': 0.8671,
    'GBP': 0.7405,
    'INR': 95.46,
    'JPY': 159.41,
    'CAD': 1.3932,
    'AUD': 1.5210,
    'CHF': 0.8920,
    'CNY': 7.2450,
  };

  /// Smart Fetcher: Checks if rates are older than 24h/daily and fetches new ones automatically
  static Future<Map<String, double>> getOrUpdateDailyRates({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final String? lastUpdatedStr = prefs.getString(_lastUpdatedKey);
    final DateTime? lastUpdated = lastUpdatedStr == null ? null : DateTime.parse(lastUpdatedStr);
    bool shouldUpdate = forceRefresh || lastUpdated == null;

    if (!shouldUpdate) {
      final DateTime now = DateTime.now();

      // Automatically update if last update was yesterday or > 24 hours ago
      final bool isDifferentDay = now.day != lastUpdated.day ||
          now.month != lastUpdated.month ||
          now.year != lastUpdated.year;

      if (isDifferentDay || now.difference(lastUpdated).inHours >= 24) {
        shouldUpdate = true;
      }
    }

    if (shouldUpdate) {
      try {
        final response = await http.get(Uri.parse(_apiUrl)).timeout(
              const Duration(seconds: 8),
            );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final Map<String, dynamic> rawRates = data['rates'];

          final Map<String, double> liveRates = {};
          rawRates.forEach((key, value) {
            liveRates[key] = (value as num).toDouble();
          });

          // Save updated rates and timestamp
          await prefs.setString(_cachedRatesKey, json.encode(liveRates));
          await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());

          return liveRates;
        }
      } catch (e) {
        // Network unavailable: fall through to cache
      }
    }

    // Return cached rates if fresh or network fetch fails
    final String? cachedJson = prefs.getString(_cachedRatesKey);
    if (cachedJson != null) {
      final Map<String, dynamic> decoded = json.decode(cachedJson);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    return defaultRates;
  }

  /// Calculates exact conversion between any two currencies using base USD rates
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required Map<String, double> rates,
  }) {
    final double fromRate = rates[fromCurrency] ?? 1.0;
    final double toRate = rates[toCurrency] ?? 1.0;

    final double amountInUSD = amount / fromRate;
    return amountInUSD * toRate;
  }
}