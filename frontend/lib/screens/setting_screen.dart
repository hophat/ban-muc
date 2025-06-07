import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/customer.dart';
import '../models/squid_type.dart';
import '../models/boat.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.loadSquidTypes();
      await dataProvider.loadCustomers();
      await dataProvider.loadBoats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Loại mực'),
            Tab(text: 'Khách hàng'),
            Tab(text: 'Thuyền'),
            Tab(text: 'Cài đặt khác'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSquidTypesTab(),
                _buildCustomersTab(),
                _buildBoatsTab(),
                _buildOtherSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildSquidTypesTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: TextEditingController(),
                  label: 'Tìm kiếm loại mực...',
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Thêm mới',
                onPressed: () => _showSquidTypeDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dataProvider.squidTypes.length,
            itemBuilder: (context, index) {
              final squidType = dataProvider.squidTypes[index];
              return ListTile(
                title: Text(squidType.name),
                subtitle: Text(squidType.description ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showSquidTypeDialog(squidType: squidType),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSquidType(squidType),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final filteredCustomers = dataProvider.customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phone ?? '').contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Tìm kiếm khách hàng...',
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Thêm mới',
                onPressed: () => _showCustomerDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return ListTile(
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showCustomerDialog(customer: customer),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCustomer(customer),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoatsTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final filteredBoats = dataProvider.boats.where((boat) {
      return boat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (boat.ownerName ?? '').contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Tìm kiếm thuyền...',
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Thêm mới',
                onPressed: () => _showBoatDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredBoats.length,
            itemBuilder: (context, index) {
              final boat = filteredBoats[index];
              return ListTile(
                title: Text(boat.name),
                subtitle: Text('Tên chủ thuyền: ${boat.ownerName ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBoatDialog(boat: boat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteBoat(boat),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOtherSettingsTab() {
    return const Center(
      child: Text('Cài đặt khác sẽ được phát triển sau'),
    );
  }

  Future<void> _showSquidTypeDialog({SquidType? squidType}) async {
    // TODO: Implement squid type dialog
  }

  Future<void> _showCustomerDialog({Customer? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(customer == null ? 'Thêm khách hàng mới' : 'Sửa thông tin khách hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Tên khách hàng',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: addressController,
                label: 'Địa chỉ',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                };

                if (customer == null) {
                  await _apiService.create('customers', data);
                } else {
                  await _apiService.update('customers', customer.id, data);
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(customer == null ? 'Thêm khách hàng thành công' : 'Cập nhật thành công')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBoatDialog({Boat? boat}) async {
    final nameController = TextEditingController(text: boat?.name ?? '');
    final ownerNameController = TextEditingController(text: boat?.ownerName ?? '');
    final phoneController = TextEditingController(text: boat?.phone ?? '');
    final descriptionController = TextEditingController(text: boat?.description ?? '');

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(boat == null ? 'Thêm thuyền mới' : 'Sửa thông tin thuyền'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Tên thuyền',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: ownerNameController,
                label: 'Tên chủ thuyền',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: descriptionController,
                label: 'Mô tả',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'name': nameController.text,
                  'owner_name': ownerNameController.text,
                  'phone': phoneController.text,
                  'description': descriptionController.text,
                };

                if (boat == null) {
                  await _apiService.create('boats', data);
                } else {
                  await _apiService.update('boats', boat.id, data);
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(boat == null ? 'Thêm thuyền thành công' : 'Cập nhật thành công')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSquidType(SquidType squidType) async {
    // TODO: Implement delete squid type
  }

  Future<void> _deleteCustomer(Customer customer) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khách hàng "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.delete('customers', customer.id);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa khách hàng thành công')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteBoat(Boat boat) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thuyền "${boat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.delete('boats', boat.id);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thuyền thành công')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')),
        );
      }
    }
  }
}

