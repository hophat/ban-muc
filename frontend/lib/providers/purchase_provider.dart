import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class PurchaseProvider with ChangeNotifier {
  final ApiService _apiService;
  List<dynamic> _purchases = [];
  bool _isLoading = false;
  String? _error;

  PurchaseProvider(this._apiService);

  List<dynamic> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPurchases({Map<String, String>? params}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _purchases = await _apiService.getPurchases(params: params);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.create('purchases', data);
      await fetchPurchases();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updatePurchase(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.update('purchases', id, data);
      await fetchPurchases();
      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePurchase(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('purchases', id);
      await fetchPurchases();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 