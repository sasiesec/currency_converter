import 'package:flutter/material.dart';
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
  final TextEditingController _amountController = TextEditingController();

  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double? _convertedAmount;
  bool _isLoading = true;

  Map<String, double> _rates = CurrencyService.defaultRates;

  @override
  void initState() {
    super.initState();
    // Automatically checks 24-hour expiration / new calendar day on screen launch
    _checkAndSyncDailyRates();
  }

  Future<void> _checkAndSyncDailyRates({bool force = false}) async {
    setState(() => _isLoading = true);

    // Fetches fresh rates if past 24 hours or if calendar day changed
    final updatedRates = await CurrencyService.getOrUpdateDailyRates(
      forceRefresh: force,
    );

    if (mounted) {
      setState(() {
        _rates = updatedRates;
        _isLoading = false;
      });

      // Recalculate output with fresh exchange rates
      _convertAndSave();
    }
  }

  void _convertAndSave() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _convertedAmount = null);
      return;
    }

    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _convertedAmount = null);
      return;
    }

    // Convert currency using cross-rate conversion formula
    final double result = CurrencyService.convert(
      amount: amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      rates: _rates,
    );

    setState(() {
      _convertedAmount = result;
    });

    // Save transaction to local daily conversion history log
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

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertAndSave();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedCurrencies = _rates.keys.toList()..sort();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Auto Sync Indicator & Manual Sync Button Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-Synced (${_rates.length} Currencies)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.cyanAccent,
                        ),
                      )
                    : const Icon(
                        Icons.sync,
                        color: Colors.cyanAccent,
                        size: 22,
                      ),
                onPressed: _isLoading
                    ? null
                    : () => _checkAndSyncDailyRates(force: true),
                tooltip: 'Force Sync Rates Now',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Glass Converter Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Live Currency Converter',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Amount Input Field
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.cyanAccent,
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => _convertAndSave(),
                ),
                const SizedBox(height: 20),

                // Dropdowns & Swap Button
                Row(
                  children: [
                    Expanded(
                      child: _buildCurrencyDropdown(
                        label: 'From',
                        currentValue: _fromCurrency,
                        currencies: sortedCurrencies,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _fromCurrency = val);
                            _convertAndSave();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.swap_horizontal_circle,
                        size: 40,
                        color: Colors.cyanAccent,
                      ),
                      onPressed: _swapCurrencies,
                      tooltip: 'Swap Currencies',
                    ),
                    Expanded(
                      child: _buildCurrencyDropdown(
                        label: 'To',
                        currentValue: _toCurrency,
                        currencies: sortedCurrencies,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _toCurrency = val);
                            _convertAndSave();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Calculated Exchange Output Card
          if (_convertedAmount != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: GlassCard(
                child: Column(
                  children: [
                    Text(
                      '${_amountController.text} $_fromCurrency =',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.greenAccent],
                      ).createShader(bounds),
                      child: Text(
                        '${_convertedAmount!.toStringAsFixed(4)} $_toCurrency',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Single Unit Exchange Ratio
                    Text(
                      '1 $_fromCurrency = ${CurrencyService.convert(amount: 1, fromCurrency: _fromCurrency, toCurrency: _toCurrency, rates: _rates).toStringAsFixed(6)} $_toCurrency',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for dropdown selector
  Widget _buildCurrencyDropdown({
    required String label,
    required String currentValue,
    required List<String> currencies,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedVal =
        currencies.contains(currentValue) ? currentValue : currencies.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedVal,
              dropdownColor: const Color(0xFF1E1E2C),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              isExpanded: true,
              items: currencies.map((String c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}