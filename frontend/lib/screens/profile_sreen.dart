import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../models/farm.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmAddressController = TextEditingController();
  final _farmPhoneController = TextEditingController();
  final _farmDescriptionController = TextEditingController();
  
  late User _user;
  late Farm _farm;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmAddressController.dispose();
    _farmPhoneController.dispose();
    _farmDescriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _user = authProvider.user!;
      _farm = authProvider.farm!;
      
      // Cập nhật các controller
      _nameController.text = _user.name;
      _emailController.text = _user.email ?? '';
      _phoneController.text = _user.phone;
      _farmNameController.text = _farm.name;
      _farmAddressController.text = _farm.address;
      _farmPhoneController.text = _farm.phone;
      _farmDescriptionController.text = _farm.description ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Cập nhật thông tin người dùng
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };
      await apiService.update('users', _user.id, userData);

      // Cập nhật thông tin farm
      final farmData = {
        'name': _farmNameController.text,
        'address': _farmAddressController.text,
        'phone': _farmPhoneController.text,
        'description': _farmDescriptionController.text,
      };
      await apiService.update('farms', _farm.id, farmData);

      // Cập nhật lại thông tin từ server
      await authProvider.checkAuthStatus();

      setState(() => _isEditing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Cá Nhân'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông Tin Cá Nhân',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Họ và tên',
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Số điện thoại phải có 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Thông Tin Trại',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _farmNameController,
                label: 'Tên trại',
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên trại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _farmAddressController,
                label: 'Địa chỉ',
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _farmPhoneController,
                label: 'Số điện thoại trại',
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại trại';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Số điện thoại phải có 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _farmDescriptionController,
                label: 'Mô tả',
                enabled: _isEditing,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
