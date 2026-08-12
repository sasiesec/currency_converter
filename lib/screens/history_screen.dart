import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversion_history.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ConversionHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService.getHistory();
    setState(() => _history = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Saved Daily Conversions', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              await StorageService.clearHistory();
              _loadHistory();
            },
          )
        ],
      ),
      body: _history.isEmpty
          ? const Center(child: Text('No saved conversions', style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  color: Colors.white.withOpacity(0.08),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.currency_exchange, color: Colors.cyanAccent),
                    title: Text(
                      '${item.fromAmount} ${item.fromCurrency} ➔ ${item.toAmount.toStringAsFixed(2)} ${item.toCurrency}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(item.timestamp),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}