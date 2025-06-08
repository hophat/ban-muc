import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
    static const String baseUrl = 'http://localhost:8000/api';
    // static const String baseUrl = 'https://banmuc.gulagi.com/api';
  
  String? _token;

  // Get stored token
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Store token
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    // Xóa tất cả các key liên quan đến auth
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('farm_data');
    await prefs.clear(); // Xóa tất cả dữ liệu trong SharedPreferences
  }

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else {
      final errorMsg = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw Exception('API Error ${response.statusCode}: $errorMsg');
    }
  }

  // Authentication
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'phone': phone,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await setToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await setToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> registerWithPhone(String phoneNumber, String pin, String name, String farmName, String farmAddress, String farmPhone, String farmDescription) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'name': name,
        'email': '${phoneNumber}@banmuc.com',
        'password': pin,
        'password_confirmation': pin,
        'phone': phoneNumber,
        'farm_name': farmName,
        'farm_address': farmAddress,
        'farm_phone': farmPhone,
        'farm_description': farmDescription,
      }),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await setToken(data['token']);
    }
    return data;
  }

  Future<void> logout() async {
    try {
      // Gọi API logout trước khi xóa token
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: await _getHeaders(),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Luôn xóa token ngay cả khi API call thất bại
      await clearToken();
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getFarm() async {
    final response = await http.get(
      Uri.parse('$baseUrl/farm'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Generic CRUD operations
  Future<List<dynamic>> getList(String endpoint, {Map<String, String>? params}) async {
    String url = '$baseUrl/$endpoint';
    if (params != null && params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    final result = _handleResponse(response);
    
    if (result is List) {
      return result;
    } else {
      throw Exception('Expected array but got ${result.runtimeType}');
    }
  }

  Future<Map<String, dynamic>> getItem(String endpoint, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> create(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> update(String endpoint, int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Specific endpoints
  Future<List<dynamic>> getSquidTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/squid-types'),
      headers: await _getHeaders(),
    );
    final result = _handleResponse(response);
    
    if (result is List) {
      return result;
    } else {
      throw Exception('Expected array but got ${result.runtimeType}');
    }
  }
  Future<List<dynamic>> getBoats() => getList('boats');
  Future<List<dynamic>> getCustomers() => getList('customers');
  Future<List<dynamic>> getPurchases({Map<String, String>? params}) => getList('purchases', params: params);
  Future<List<dynamic>> getSales({Map<String, String>? params}) => getList('sales', params: params);
  Future<List<dynamic>> getExpenses({Map<String, String>? params}) => getList('expenses', params: params);

  // Reports
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/dashboard'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getRevenueReport({Map<String, String>? params}) async {
    String url = '$baseUrl/reports/revenue';
    if (params != null && params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getExpenseReport({Map<String, String>? params}) async {
    String url = '$baseUrl/reports/expenses';
    if (params != null && params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfitReport({Map<String, String>? params}) async {
    String url = '$baseUrl/reports/profit';
    if (params != null && params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDebtReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/debts'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Update payment status
  Future<Map<String, dynamic>> updatePaymentStatus(int saleId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sales/$saleId/payment-status'),
      headers: await _getHeaders(),
      body: json.encode({'payment_status': status}),
    );
    return _handleResponse(response);
  }

  // Farm
  Future<Map<String, dynamic>> createFarm(String name, String address, String phone, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farm-setup'),
      headers: await _getHeaders(),
      body: json.encode({'name': name, 'address': address, 'phone': phone, 'description': description}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updatePurchase(
    int id, {
    required double weight,
    required double unitPrice,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/purchases/$id'),
        headers: await _getHeaders(),
        body: json.encode({
          'weight': weight,
          'unit_price': unitPrice,
          'total_amount': totalAmount,
          if (notes != null) 'notes': notes,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Update purchase error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSale(
    int id, {
    required double weight,
    required double unitPrice,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sales/$id'),
        headers: await _getHeaders(),
        body: json.encode({
          'weight': weight,
          'unit_price': unitPrice,
          'total_amount': totalAmount,
          if (notes != null) 'notes': notes,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Update sale error: $e');
      rethrow;
    }
  }
} 