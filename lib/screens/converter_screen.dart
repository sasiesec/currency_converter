import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversion_history.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _leftController = TextEditingController(text: '1.0');
  final TextEditingController _rightController = TextEditingController();

  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  bool _isLoading = true;
  DateTime? _lastUpdatedTime;
  String _selectedTimeFrame = '1Y'; // 1D, 5D, 1M, 1Y, 5Y, Max

  Map<String, double> _rates = CurrencyService.defaultRates;

  final Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'INR': 'Indian Rupee',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
  };

  @override
  void initState() {
    super.initState();
    _checkAndSyncDailyRates();
  }

  Future<void> _checkAndSyncDailyRates({bool force = false}) async {
    setState(() => _isLoading = true);
    final updatedRates = await CurrencyService.getOrUpdateDailyRates(forceRefresh: force);
    if (mounted) {
      setState(() {
        _rates = updatedRates;
        _isLoading = false;
        _lastUpdatedTime = DateTime.now();
      });
      _onLeftChanged(_leftController.text);
    }
  }

  void _onLeftChanged(String value) {
    if (value.isEmpty) {
      _rightController.text = '';
      return;
    }
    final double? amount = double.tryParse(value);
    if (amount == null) return;

    final double result = CurrencyService.convert(
      amount: amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      rates: _rates,
    );

    _rightController.text = result.toStringAsFixed(2);

    final historyItem = ConversionHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromAmount: amount,
      fromCurrency: _fromCurrency,
      toAmount: result,
      toCurrency: _toCurrency,
      timestamp: DateTime.now(),
    );
    StorageService.saveConversion(historyItem);
  }

  void _onRightChanged(String value) {
    if (value.isEmpty) {
      _leftController.text = '';
      return;
    }
    final double? amount = double.tryParse(value);
    if (amount == null) return;

    final double result = CurrencyService.convert(
      amount: amount,
      fromCurrency: _toCurrency,
      toCurrency: _fromCurrency,
      rates: _rates,
    );

    _leftController.text = result.toStringAsFixed(2);
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _onLeftChanged(_leftController.text);
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedCurrencies = _rates.keys.toList()..sort();
    
    final double singleUnitConversion = CurrencyService.convert(
      amount: 1.0,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      rates: _rates,
    );

    final fromName = _currencyNames[_fromCurrency] ?? _fromCurrency;
    final toName = _currencyNames[_toCurrency] ?? _toCurrency;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rate Header Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 $fromName =',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.cyanAccent, Colors.greenAccent],
                  ).createShader(bounds),
                  child: Text(
                    '${singleUnitConversion.toStringAsFixed(2)} $toName',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _lastUpdatedTime != null
                          ? 'Last updated · ${DateFormat('MMMM dd at h:mm a').format(_lastUpdatedTime!)}'
                          : 'Live Rates Synced',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                            )
                          : const Icon(Icons.sync, color: Colors.cyanAccent, size: 18),
                      onPressed: _isLoading ? null : () => _checkAndSyncDailyRates(force: true),
                      tooltip: 'Sync Rates',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Converter Input Card
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _fromCurrency,
                        currencies: sortedCurrencies,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _fromCurrency = val);
                            _onLeftChanged(_leftController.text);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, color: Colors.cyanAccent, size: 28),
                      onPressed: _swapCurrencies,
                      tooltip: 'Swap Currencies',
                    ),
                    Expanded(
                      child: _buildDropdown(
                        value: _toCurrency,
                        currencies: sortedCurrencies,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _toCurrency = val);
                            _onLeftChanged(_leftController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _leftController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onLeftChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _rightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onRightChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Google Finance Style Trend Chart (Graph) Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time Range Filter Buttons (1D, 5D, 1M, 1Y, 5Y, Max)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['1D', '5D', '1M', '1Y', '5Y', 'Max'].map((tf) {
                    final isSelected = _selectedTimeFrame == tf;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeFrame = tf),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            color: isSelected ? Colors.greenAccent : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Financial Graph Widget
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: FinancialGraphPainter(
                      baseRate: singleUnitConversion,
                      timeFrame: _selectedTimeFrame,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Month / X-Axis labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sep', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Nov', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Feb', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Apr', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Jun', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Sep', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> currencies,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currencies.contains(value) ? value : currencies.first,
          dropdownColor: const Color(0xFF1E1E2C),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          isExpanded: true,
          items: currencies.map((c) {
            final name = _currencyNames[c] ?? c;
            return DropdownMenuItem<String>(
              value: c,
              child: Text('$c - $name', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Custom Painter that generates a realistic financial line chart with gradient fill
class FinancialGraphPainter extends CustomPainter {
  final double baseRate;
  final String timeFrame;

  FinancialGraphPainter({required this.baseRate, required this.timeFrame});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint shaderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.greenAccent.withOpacity(0.35),
          Colors.greenAccent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Generate trend points based on time frame variation
    final int pointCount = timeFrame == '1D' ? 12 : (timeFrame == '5D' ? 20 : 35);
    final List<double> points = [];
    final Random rand = Random(baseRate.toInt());

    double currentVal = baseRate * 0.94;
    for (int i = 0; i < pointCount; i++) {
      currentVal += (rand.nextDouble() - 0.45) * (baseRate * 0.015);
      points.add(currentVal);
    }
    points[pointCount - 1] = baseRate; // Ensure last point matches exact current rate

    final double minVal = points.reduce(min);
    final double maxVal = points.reduce(max);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final Path path = Path();
    final Path fillPath = Path();

    final double dx = size.width / (pointCount - 1);

    for (int i = 0; i < pointCount; i++) {
      final double x = i * dx;
      final double normalizedY = (points[i] - minVal) / range;
      final double y = size.height - (normalizedY * (size.height * 0.8) + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw gradient shade underneath
    canvas.drawPath(fillPath, shaderPaint);
    // Draw trend line
    canvas.drawPath(path, linePaint);

    // Draw ending point glowing circle
    final double lastX = size.width;
    final double lastNormalizedY = (points.last - minVal) / range;
    final double lastY = size.height - (lastNormalizedY * (size.height * 0.8) + size.height * 0.1);

    final Paint dotPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(Offset(lastX, lastY), 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}