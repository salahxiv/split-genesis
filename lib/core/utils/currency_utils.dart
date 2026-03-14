import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const currencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CHF': 'CHF',
  'CNY': '¥',
  'INR': '₹',
  'MXN': 'MX\$',
  'BRL': 'R\$',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'PLN': 'zł',
  'CZK': 'Kč',
  'HUF': 'Ft',
  'RON': 'lei',
  'TRY': '₺',
  'RUB': '₽',
  'KRW': '₩',
  'SGD': 'S\$',
  'HKD': 'HK\$',
  'NZD': 'NZ\$',
  'ZAR': 'R',
};

String formatCurrency(double amount, [String currency = 'USD']) {
  final symbol = currencySymbols[currency] ?? currency;
  if (currency == 'JPY' || currency == 'KRW' || currency == 'HUF') {
    return '$symbol${amount.round()}';
  }
  return '$symbol${amount.toStringAsFixed(2)}';
}

String getCurrencySymbol(String currency) {
  return currencySymbols[currency] ?? currency;
}

/// Currency converter using EUR as the base currency.
/// Fetches live rates from Frankfurter.app (free, no API key, FOSS).
/// Caches rates for 24h via SharedPreferences.
/// Falls back to static rates when offline.
class CurrencyConverter {
  CurrencyConverter._();

  static const _cacheKey = 'frankfurter_rates_json';
  static const _cacheTimestampKey = 'frankfurter_rates_timestamp';
  static const _cacheTtlMs = 24 * 60 * 60 * 1000; // 24 hours

  // In-memory cache — populated on first use
  static Map<String, double>? _liveRates;

  /// Static fallback rates relative to EUR (1 EUR = X currency).
  static const Map<String, double> _staticRatesFromEur = {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.86,
    'JPY': 161.5,
    'CAD': 1.47,
    'AUD': 1.66,
    'CHF': 0.97,
    'CNY': 7.83,
    'INR': 90.1,
    'MXN': 18.4,
    'BRL': 5.35,
    'SEK': 11.3,
    'NOK': 11.5,
    'DKK': 7.46,
    'PLN': 4.27,
    'CZK': 25.3,
    'HUF': 395.0,
    'RON': 4.97,
    'TRY': 35.0,
    'RUB': 98.0,
    'KRW': 1450.0,
    'SGD': 1.46,
    'HKD': 8.45,
    'NZD': 1.80,
    'ZAR': 20.2,
  };

  /// Active rates — live if available, otherwise static fallback.
  static Map<String, double> get _rates => _liveRates ?? _staticRatesFromEur;

  /// Initialises the converter by loading cached or fetching live rates.
  /// Call once at app startup (e.g. in main.dart after WidgetsFlutterBinding).
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final cachedTs = prefs.getInt(_cacheTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (cachedJson != null && (now - cachedTs) < _cacheTtlMs) {
        // Use cached rates
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        _liveRates = {
          'EUR': 1.0,
          ...decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
        };
        debugPrint('[Currency] Using cached rates (age: ${(now - cachedTs) ~/ 60000}min)');
        return;
      }

      // Fetch fresh rates from Frankfurter API
      await _fetchAndCache(prefs);
    } catch (e) {
      debugPrint('[Currency] init failed, using static rates: $e');
    }
  }

  /// Forces a refresh of live rates (ignores cache).
  static Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _fetchAndCache(prefs);
    } catch (e) {
      debugPrint('[Currency] refresh failed: $e');
    }
  }

  static Future<void> _fetchAndCache(SharedPreferences prefs) async {
    const url = 'https://api.frankfurter.app/latest?from=EUR';
    debugPrint('[Currency] Fetching live rates from $url');

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = body['rates'] as Map<String, dynamic>;

      _liveRates = {
        'EUR': 1.0,
        ...rates.map((k, v) => MapEntry(k, (v as num).toDouble())),
      };

      await prefs.setString(_cacheKey, jsonEncode(rates));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('[Currency] Live rates updated (${_liveRates!.length} currencies)');
    } else {
      debugPrint('[Currency] API returned ${response.statusCode}, using fallback rates');
    }
  }

  /// Convert [amountCents] from [fromCurrency] to EUR cents.
  /// Returns amountCents unchanged if the currency is unknown (fail-open).
  static int toEurCents(int amountCents, String fromCurrency) {
    if (fromCurrency == 'EUR') return amountCents;
    final rate = _rates[fromCurrency];
    if (rate == null || rate == 0) return amountCents;
    return (amountCents / rate).round();
  }

  /// Convert [eurCents] from EUR to [toCurrency] cents.
  static int fromEurCents(int eurCents, String toCurrency) {
    if (toCurrency == 'EUR') return eurCents;
    final rate = _rates[toCurrency];
    if (rate == null) return eurCents;
    return (eurCents * rate).round();
  }

  /// Convert [amountCents] from [fromCurrency] to [toCurrency].
  static int convert(int amountCents, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amountCents;
    final eurCents = toEurCents(amountCents, fromCurrency);
    return fromEurCents(eurCents, toCurrency);
  }

  /// Whether a currency code is known (live or static).
  static bool isSupported(String currency) => _rates.containsKey(currency);

  /// Sorted list of supported currency codes.
  static List<String> get supportedCurrencies =>
      _rates.keys.toList()..sort();

  /// True when live rates have been loaded successfully.
  static bool get hasLiveRates => _liveRates != null;
}
