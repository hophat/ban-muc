import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPinInput = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  void _verifyPhone() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showPinInput = true;
        _errorMessage = null;
      });
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String pin = _pinControllers.map((c) => c.text).join();
      try {
        await authProvider.login(_phoneController.text, pin);
        if (authProvider.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          setState(() { _errorMessage = authProvider.error ?? 'Đăng nhập thất bại'; });
        }
      } catch (e) {
        setState(() { _errorMessage = 'Đăng nhập thất bại: $e'; });
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _pinFocusNodes[index + 1].requestFocus();
      } else {
        _login();
      }
    }
  }

  void _onPinBackspace(int index) {
    if (index > 0) {
      _pinControllers[index - 1].clear();
      _pinFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo section
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.waves,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Title
                Text(
                  'QUẢN LÝ TRẠI MỰC',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Hệ thống quản lý trang trại nuôi mực chuyên nghiệp',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 48),
                
                // Login form
                Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _showPinInput ? 'NHẬP MÃ PIN' : 'ĐĂNG NHẬP HỆ THỐNG',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 32),

                        if (!_showPinInput) ...[
                          // Phone input
                          Text('Số điện thoại', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Nhập số điện thoại',
                              hintStyle: TextStyle(fontSize: 14),
                              prefixIcon: Icon(Icons.phone, color: Color(0xFF757575)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                              if (value.length < 9) return 'Số điện thoại không hợp lệ';
                              return null;
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Demo account info box
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFF1565C0).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Tài khoản demo',
                                      style: TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Số điện thoại: 0123456789\nMã PIN: 123456',
                                  style: TextStyle(
                                    color: Color(0xFF424242),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Continue button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1565C0),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'TIẾP TỤC',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/phone-input'),
                                child: Text(
                                  'Đăng ký bằng số điện thoại',
                                  style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // PIN input
                          Text('Nhập mã PIN 6 số', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 48,
                                height: 48,
                                child: TextFormField(
                                  controller: _pinControllers[index],
                                  focusNode: _pinFocusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  obscureText: true,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (value) => _onPinChanged(value, index),
                                  onTap: () {
                                    _pinControllers[index].selection = TextSelection.fromPosition(
                                      TextPosition(offset: _pinControllers[index].text.length),
                                    );
                                  },
                                  onEditingComplete: () {
                                    if (_pinControllers[index].text.isEmpty && index > 0) {
                                      _onPinBackspace(index);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return '';
                                    if (!RegExp(r'^[0-9]$').hasMatch(value)) return '';
                                    return null;
                                  },
                                ),
                              );
                            }),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Back button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showPinInput = false;
                                for (var controller in _pinControllers) {
                                  controller.clear();
                                }
                              });
                            },
                            child: Text(
                              'Quay lại',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                        
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Color(0xFFD32F2F)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 