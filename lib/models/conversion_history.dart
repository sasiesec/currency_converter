import 'dart:convert';

class ConversionHistory {
  final String id;
  final double fromAmount;
  final String fromCurrency;
  final double toAmount;
  final String toCurrency;
  final DateTime timestamp;

  ConversionHistory({
    required this.id,
    required this.fromAmount,
    required this.fromCurrency,
    required this.toAmount,
    required this.toCurrency,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromAmount': fromAmount,
      'fromCurrency': fromCurrency,
      'toAmount': toAmount,
      'toCurrency': toCurrency,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversionHistory.fromMap(Map<String, dynamic> map) {
    return ConversionHistory(
      id: map['id'],
      fromAmount: (map['fromAmount'] as num).toDouble(),
      fromCurrency: map['fromCurrency'],
      toAmount: (map['toAmount'] as num).toDouble(),
      toCurrency: map['toCurrency'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());
  factory ConversionHistory.fromJson(String source) =>
      ConversionHistory.fromMap(json.decode(source));
}