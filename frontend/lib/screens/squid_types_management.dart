import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/squid_type.dart';

class SquidTypesManagementScreen extends StatefulWidget {
  const SquidTypesManagementScreen({super.key});

  @override
  State<SquidTypesManagementScreen> createState() => _SquidTypesManagementScreenState();
}

class _SquidTypesManagementScreenState extends State<SquidTypesManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<SquidType> _squidTypes = [];
  bool _isEditing = false;
  SquidType? _editingSquidType;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSquidTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSquidTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSquidTypes();
      setState(() {
        _squidTypes = response.map((json) => SquidType.fromJson(json)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách loại mực: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
      };

      if (_isEditing && _editingSquidType != null) {
        await _apiService.update('squid-types', _editingSquidType!.id, data);
      } else {
        await _apiService.create('squid-types', data);
      }

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _isEditing = false;
        _editingSquidType = null;
      });
      await _loadSquidTypes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Cập nhật thành công' : 'Thêm mới thành công'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSquidType(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa loại mực này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.delete('squid-types', id);
      await _loadSquidTypes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startEditing(SquidType squidType) {
    setState(() {
      _isEditing = true;
      _editingSquidType = squidType;
      _nameController.text = squidType.name;
      _descriptionController.text = squidType.description ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý loại mực'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isEditing ? 'Chỉnh sửa loại mực' : 'Thêm loại mực mới',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên loại mực',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Vui lòng nhập tên loại mực' : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isEditing)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _editingSquidType = null;
                                        _nameController.clear();
                                        _descriptionController.clear();
                                      });
                                    },
                                    child: const Text('Hủy'),
                                  ),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  child: Text(_isEditing ? 'Cập nhật' : 'Thêm mới'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: _squidTypes.length,
                        itemBuilder: (context, index) {
                          final squidType = _squidTypes[index];
                          return ListTile(
                            title: Text(squidType.name),
                            subtitle: squidType.description != null
                                ? Text(squidType.description!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _startEditing(squidType),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSquidType(squidType.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
