import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CurrencyApp());
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Currency & Spending Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F2027),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();

  // Selected Currencies
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  // State Variables
  double? _convertedAmount;
  String? _errorMessage;

  // Static exchange rates relative to 1 USD (for demonstration)
  // Replace these with dynamic values from a REST API (e.g., exchangerate-api.com)
  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 155.20,
    'INR': 83.45,
    'CAD': 1.36,
    'AUD': 1.51,
  };

  void _convertCurrency() {
    setState(() {
      _errorMessage = null;
    });

    final String text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
        _convertedAmount = null;
      });
      return;
    }

    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid positive number';
        _convertedAmount = null;
      });
      return;
    }

    final double fromRate = _exchangeRates[_fromCurrency] ?? 1.0;
    final double toRate = _exchangeRates[_toCurrency] ?? 1.0;

    // Convert amount to USD base first, then convert to target currency
    final double amountInUsd = amount / fromRate;
    final double result = amountInUsd * toRate;

    setState(() {
      _convertedAmount = result;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;

      // Recalculate if there is already an input amount
      if (_amountController.text.isNotEmpty) {
        _convertCurrency();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _exchangeRates.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 100',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              onChanged: (_) => _convertCurrency(),
            ),
            const SizedBox(height: 24),

            // Currency Selection Row
            Row(
              children: [
                // From Currency Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromCurrency,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    items: currencies.map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _fromCurrency = newValue);
                        _convertCurrency();
                      }
                    },
                  ),
                ),

                // Swap Button
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 32),
                  onPressed: _swapCurrencies,
                  tooltip: 'Swap Currencies',
                ),

                // To Currency Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toCurrency,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    items: currencies.map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _toCurrency = newValue);
                        _convertCurrency();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Convert Action Button
            ElevatedButton(
              onPressed: _convertCurrency,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Convert', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 32),

            // Conversion Result Display
            if (_convertedAmount != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '${_amountController.text} $_fromCurrency =',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_convertedAmount!.toStringAsFixed(2)} $_toCurrency',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
