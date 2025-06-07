import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService;
  List<dynamic> _expenses = [];
  bool _isLoading = false;
  String? _error;

  ExpenseProvider(this._apiService);

  List<dynamic> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExpenses({Map<String, String>? params}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _apiService.getExpenses(params: params);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.create('expenses', data);
      await fetchExpenses();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateExpense(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.update('expenses', id, data);
      await fetchExpenses();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('expenses', id);
      await fetchExpenses();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 