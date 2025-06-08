import 'package:flutter/foundation.dart';
import '../models/farm.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _user;
  Farm? _farm;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider(this._apiService);

  User? get user => _user;
  Farm? get farm => _farm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Demo accounts
  final Map<String, String> _demoAccounts = {
    '0123456789': '123456', // Admin account
    '0987654321': '654321', // Staff account
  };

  Future<bool> login(String phone, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Nếu không phải tài khoản demo, gọi API
      final response = await _apiService.login(phone, pin);
      if (response['token'] != null) {
        _user = User(
          id: response['user']['id'],
          name: response['user']['name'],
          email: response['user']['email'],
          farm: response['user']['farm'] != null ? Farm.fromJson(response['user']['farm']) : null,
          phone: response['user']['phone'],
          role: response['user']['role'],
          createdAt: DateTime.parse(response['user']['created_at']),
          updatedAt: DateTime.parse(response['user']['updated_at']),
        );
        
        // Lấy thông tin farm nếu user có farm
        if (_user?.farm != null) {
          _farm = _user!.farm;
        } else {
          // Nếu là admin, lấy farm từ ownedFarm
          if (_user?.role == 'admin') {
            final farmResponse = await _apiService.getFarm();
            if (farmResponse != null) {
              _farm = Farm(
                id: farmResponse['id'],
                name: farmResponse['name'],
                address: farmResponse['address'],
                phone: farmResponse['phone'],
                description: farmResponse['description'],
                createdAt: DateTime.parse(farmResponse['created_at']),
                updatedAt: DateTime.parse(farmResponse['updated_at']),
              );
            }
          }
        }
        
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw 'Đăng nhập thất bại';
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Future<bool> register({
  //   required String name,
  //   required String email,
  //   required String password,
  // }) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     final response = await _apiService.register(name, email, password);
  //     if (response['token'] != null) {
  //       _user = User(
  //         id: response['user']['id'],
  //         name: response['user']['name'],
  //         email: response['user']['email'],
  //         phone: response['user']['phone'],
  //         role: response['user']['role'],
  //         createdAt: DateTime.parse(response['user']['created_at']),
  //         updatedAt: DateTime.parse(response['user']['updated_at']),
  //       );
  //       _isAuthenticated = true;
  //       _isLoading = false;
  //       notifyListeners();
  //       return true;
  //     }
  //     throw 'Đăng ký thất bại';
  //   } catch (e) {
  //     _error = e.toString();
  //     _isAuthenticated = false;
  //     _isLoading = false;
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<bool> registerWithPhone({
    required String phoneNumber,
    required String pin,
    required String name,
    required String farmName,
    required String farmAddress,
    required String farmPhone,
    required String farmDescription,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.registerWithPhone(phoneNumber, pin, name, farmName, farmAddress, farmPhone, farmDescription);
      if (response['token'] != null) {
        _user = User(
          id: response['user']['id'],
          name: response['user']['name'],
          email: response['user']['email'],
          phone: response['user']['phone'],
          role: 'admin',
          createdAt: DateTime.parse(response['user']['created_at']),
          updatedAt: DateTime.parse(response['user']['updated_at']),
        );
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw 'Đăng ký thất bại';
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Reset tất cả state
      _user = null;
      _farm = null;
      _isAuthenticated = false;
      _error = null;
      _isLoading = false;
      
      // Gọi API logout và xóa token
      await _apiService.logout();
    } catch (e) {
      print('Logout error in AuthProvider: $e');
      // Vẫn reset state ngay cả khi có lỗi
      _user = null;
      _farm = null;
      _isAuthenticated = false;
      _error = null;
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      final userResponse = await _apiService.getCurrentUser();
      if (userResponse != null) {
        _user = User(
          id: userResponse['id'],
          name: userResponse['name'],
          email: userResponse['email'],
          phone: userResponse['phone'],
          role: userResponse['role'],
          farm: userResponse['farm'] != null ? Farm.fromJson(userResponse['farm']) : null,
          createdAt: DateTime.parse(userResponse['created_at']),
          updatedAt: DateTime.parse(userResponse['updated_at']),
        );

        // Lấy thông tin farm nếu user có farm
        if (_user?.farm != null) {
          _farm = _user!.farm;
        } else {
          // Nếu là admin, lấy farm từ ownedFarm
          if (_user?.role == 'admin') {
            final farmResponse = await _apiService.getFarm();
            if (farmResponse != null) {
              _farm = Farm(
                id: farmResponse['id'],
                name: farmResponse['name'],
                address: farmResponse['address'],
                phone: farmResponse['phone'],
                description: farmResponse['description'],
                createdAt: DateTime.parse(farmResponse['created_at']),
                updatedAt: DateTime.parse(farmResponse['updated_at']),
              );
            }
          }
        }

        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 