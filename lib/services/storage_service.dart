import '../models/conversion_history.dart';
import '../models/expense.dart';

class SharedPreferences {
  SharedPreferences._internal();
  static final SharedPreferences _instance = SharedPreferences._internal();
  final Map<String, Object> _storage = {};

  static Future<SharedPreferences> getInstance() async => _instance;

  double? getDouble(String key) => _storage[key] as double?;

  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  List<String>? getStringList(String key) => _storage[key] as List<String>?;

  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }

  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }
}

class StorageService {
  static const String _historyKey = 'conversion_history';
  static const String _expensesKey = 'daily_expenses';
  static const String _initialFundsKey = 'initial_funds';

  // --- INITIAL FUNDS / BUDGET ---
  static Future<double> getInitialFunds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_initialFundsKey) ?? 1000.00; // Default $1000 if not set
  }

  static Future<void> setInitialFunds(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_initialFundsKey, amount);
  }

  // --- CONVERSION HISTORY ---
  static Future<List<ConversionHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_historyKey);
    if (jsonList == null) return [];
    return jsonList.map((item) => ConversionHistory.fromJson(item)).toList();
  }

  static Future<void> saveConversion(ConversionHistory item) async {
    final prefs = await SharedPreferences.getInstance();
    List<ConversionHistory> history = await getHistory();
    history.insert(0, item);
    if (history.length > 50) history = history.sublist(0, 50);
    final List<String> jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // --- SPENDING / EXPENSES ---
  static Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_expensesKey);
    if (jsonList == null) return [];
    return jsonList.map((item) => Expense.fromJson(item)).toList();
  }

  static Future<void> addExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    List<Expense> expenses = await getExpenses();
    expenses.insert(0, expense);
    final List<String> jsonList = expenses.map((e) => e.toJson()).toList();
    await prefs.setStringList(_expensesKey, jsonList);
  }

  static Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Expense> expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == id);
    final List<String> jsonList = expenses.map((e) => e.toJson()).toList();
    await prefs.setStringList(_expensesKey, jsonList);
  }
}