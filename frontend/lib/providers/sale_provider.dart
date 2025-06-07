import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SaleProvider with ChangeNotifier {
  final ApiService _apiService;
  List<dynamic> _sales = [];
  bool _isLoading = false;
  String? _error;

  SaleProvider(this._apiService);

  List<dynamic> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSales({Map<String, String>? params}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _apiService.getSales(params: params);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.create('sales', data);
      await fetchSales();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateSale(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.update('sales', id, data);
      await fetchSales();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSale(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('sales', id);
      await fetchSales();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 