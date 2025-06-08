import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PinSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const PinSetupScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmAddressController = TextEditingController();
  final _farmPhoneController = TextEditingController();
  final _farmDescriptionController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _nameController.dispose();
    _farmNameController.dispose();
    _farmAddressController.dispose();
    _farmPhoneController.dispose();
    _farmDescriptionController.dispose();
    super.dispose();
  }

  void _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String pin = _controllers.map((controller) => controller.text).join();
    
    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ 6 số PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await authProvider.registerWithPhone(
        name: _nameController.text,
        phoneNumber: widget.phoneNumber,
        pin: pin,
        farmName: _farmNameController.text,
        farmAddress: _farmAddressController.text,
        farmPhone: _farmPhoneController.text,
        farmDescription: _farmDescriptionController.text,
      );

      // Navigate to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thành công! Chào mừng bạn đến với hệ thống.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng ký thất bại: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
  }

  void _onPinBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Color(0xFF424242), size: 28),
        ),
        title: Text(
          'Thiết lập tài khoản',
          style: TextStyle(
            color: Color(0xFF424242),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên của bạn',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 32),
                
                // PIN section
                Text(
                  'Thiết lập mã PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'Mã PIN sẽ được sử dụng để đăng nhập vào hệ thống',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // PIN input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 48,
                      height: 48,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onPinChanged(value, index),
                        onTap: () {
                          _controllers[index].selection = TextSelection.fromPosition(
                            TextPosition(offset: _controllers[index].text.length),
                          );
                        },
                        onEditingComplete: () {
                          if (_controllers[index].text.isEmpty && index > 0) {
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
                
                SizedBox(height: 32),
                
                // Farm information section
                Text(
                  'Thông tin trại hàng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Farm name field
                TextFormField(
                  controller: _farmNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên trại',
                    hintText: 'Nhập tên trại hàng của bạn',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên trại';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Farm address field
                TextFormField(
                  controller: _farmAddressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ trại',
                    hintText: 'Nhập địa chỉ trại hàng',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ trại';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Farm phone field
                TextFormField(
                  controller: _farmPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại trại',
                    hintText: 'Nhập số điện thoại liên hệ trại',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại trại';
                    }
                    if (value.length < 10) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Farm description field
                TextFormField(
                  controller: _farmDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả trại (không bắt buộc)',
                    hintText: 'Nhập mô tả về trại hàng của bạn',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Security tips
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF1565C0).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lưu ý bảo mật:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildSecurityTip('Mã PIN phải có 6 chữ số'),
                      SizedBox(height: 8),
                      _buildSecurityTip('Không chia sẻ mã PIN với người khác'),
                      SizedBox(height: 8),
                      _buildSecurityTip('Sử dụng mã PIN khác với các tài khoản khác'),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFD32F2F).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Complete button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Hoàn thành'),
                  ),
                ),
                
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ),
      ],
    );
  }
} 