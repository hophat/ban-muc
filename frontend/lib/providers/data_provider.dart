import 'package:flutter/foundation.dart';
import '../models/squid_type.dart';
import '../models/boat.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<SquidType> _squidTypes = [];
  List<Boat> _boats = [];
  List<Customer> _customers = [];
  List<Purchase> _purchases = [];
  List<Sale> _sales = [];
  List<Expense> _expenses = [];
  
  bool _isLoading = false;
  String? _error;

  List<SquidType> get squidTypes => _squidTypes;
  List<Boat> get boats => _boats;
  List<Customer> get customers => _customers;
  List<Purchase> get purchases => _purchases;
  List<Sale> get sales => _sales;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all data including master data and transactions
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadMasterData(),
        loadPurchases(),
        loadSales(),
        loadExpenses(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all master data
  Future<void> loadMasterData() async {
    try {
      await Future.wait([
        loadSquidTypes(),
        loadBoats(),
        loadCustomers(),
      ]);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Squid Types
  Future<void> loadSquidTypes() async {
    try {
      final data = await _apiService.getSquidTypes();
      _squidTypes = data.map((json) => SquidType.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Customers
  Future<void> loadCustomers() async {
    try {
      final data = await _apiService.getCustomers();
      _customers = data.map((json) => Customer.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Boats
  Future<void> loadBoats() async {
    try {
      final response = await _apiService.getBoats();
      _boats = response.map((json) => Boat.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Purchases
  Future<void> loadPurchases() async {
    try {
      final data = await _apiService.getPurchases();
      _purchases = data.map((json) => Purchase.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Sales
  Future<void> loadSales() async {
    try {
      final data = await _apiService.getSales();
      _sales = data.map((json) => Sale.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Expenses
  Future<void> loadExpenses() async {
    try {
      final data = await _apiService.getExpenses();
      _expenses = data.map((json) => Expense.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Helper methods
  SquidType? getSquidTypeById(int id) {
    try {
      return _squidTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  Boat? getBoatById(int id) {
    try {
      return _boats.firstWhere((boat) => boat.id == id);
    } catch (e) {
      return null;
    }
  }

  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> addBoat(Boat boat) async {
    try {
      final response = await _apiService.create('boats', boat.toJson());
      _boats.add(Boat.fromJson(response));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBoat(Boat boat) async {
    try {
      final response = await _apiService.update('boats', boat.id, boat.toJson());
      final index = _boats.indexWhere((b) => b.id == boat.id);
      if (index != -1) {
        _boats[index] = Boat.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBoat(int id) async {
    try {
      await _apiService.delete('boats', id);
      _boats.removeWhere((boat) => boat.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
} 