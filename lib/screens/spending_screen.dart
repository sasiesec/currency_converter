import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  List<Expense> _expenses = [];
  double _creditAmount = 1000.00; // Default total credit funds

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _creditController = TextEditingController();

  final String _selectedCurrency = 'USD';
  final String _selectedCategory = 'General';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await StorageService.getExpenses();
    final funds = await StorageService.getInitialFunds();
    setState(() {
      _expenses = list;
      _creditAmount = funds;
    });
  }

  // Calculated Spending Total
  double get _totalSpending {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculated Remaining Balance (Credit Total - Spending)
  double get _balanceAmount {
    return _creditAmount - _totalSpending;
  }

  // Modal to Set/Update Total Credit Amount
  void _showSetCreditDialog() {
    _creditController.text = _creditAmount.toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Total Credit Amount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _creditController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.cyanAccent),
            labelText: 'Total Credit Funds',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              final newCredit = double.tryParse(_creditController.text);
              if (newCredit != null && newCredit >= 0) {
                await StorageService.setInitialFunds(newCredit);
                _loadData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet to Add Spending
  void _showAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Spending',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Expense Description',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount Spent',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final titleText = _titleController.text.trim();

                if (titleText.isEmpty || amountText.isEmpty) return;
                final parsedAmount = double.tryParse(amountText);
                if (parsedAmount == null || parsedAmount <= 0) return;

                final expense = Expense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleText,
                  amount: parsedAmount,
                  currency: _selectedCurrency,
                  category: _selectedCategory,
                  date: DateTime.now(),
                );

                await StorageService.addExpense(expense);
                _titleController.clear();
                _amountController.clear();
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Deduct Spending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Spending', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddExpenseModal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Glass Balance Breakdown Card: Credit - Spending = Balance
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Credit Amount', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                      onPressed: _showSetCreditDialog,
                      tooltip: 'Set Total Credit Amount',
                    ),
                  ],
                ),
                Text(
                  '\$${_creditAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Spending Sub-block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spending Amount', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '-\$${_totalSpending.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),

                    const Text('-', style: TextStyle(color: Colors.white38, fontSize: 24, fontWeight: FontWeight.bold)),

                    // Remaining Balance Sub-block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Balance Amount', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_balanceAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _balanceAmount < 0 ? Colors.red : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Daily Expenses', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _expenses.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No expenses recorded', style: TextStyle(color: Colors.white38))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final item = _expenses[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.withOpacity(0.4),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await StorageService.deleteExpense(item.id);
                        _loadData();
                      },
                      child: Card(
                        color: Colors.white.withOpacity(0.08),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                          title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(item.date), style: const TextStyle(color: Colors.white54)),
                          trailing: Text(
                            '-${item.amount.toStringAsFixed(2)} ${item.currency}',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}