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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.category_outlined),
              text: 'Loại hàng',
              iconMargin: const EdgeInsets.only(bottom: 8),
            ),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: 'Khách hàng',
              iconMargin: const EdgeInsets.only(bottom: 8),
            ),
            Tab(
              icon: const Icon(Icons.directions_boat_outlined),
              text: 'Thuyền',
              iconMargin: const EdgeInsets.only(bottom: 8),
            ),
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
              ],
            ),
    );
  }

  Widget _buildTabContent({
    required String searchLabel,
    required List<Widget> children,
    required VoidCallback onAddPressed,
    required String emptyMessage,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: searchLabel,
                    prefixIcon: Icon(Icons.search, color: Color(0xFF1565C0)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Color(0xFF757575)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Thêm mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: children,
                ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSquidTypesTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final filteredSquidTypes = dataProvider.squidTypes.where((type) {
      return type.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (type.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return _buildTabContent(
      searchLabel: 'Tìm kiếm loại hàng...',
      onAddPressed: () => _showSquidTypeDialog(),
      emptyMessage: _searchQuery.isNotEmpty
          ? 'Không tìm thấy loại hàng phù hợp'
          : 'Chưa có loại hàng nào. Nhấn "Thêm mới" để tạo.',
      children: filteredSquidTypes.map((type) => _buildSquidTypeItem(type)).toList(),
    );
  }

  Widget _buildCustomersTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final filteredCustomers = dataProvider.customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phone ?? '').contains(_searchQuery);
    }).toList();

    return _buildTabContent(
      searchLabel: 'Tìm kiếm khách hàng...',
      onAddPressed: () => _showCustomerDialog(),
      emptyMessage: _searchQuery.isNotEmpty
          ? 'Không tìm thấy khách hàng phù hợp'
          : 'Chưa có khách hàng nào. Nhấn "Thêm mới" để tạo.',
      children: filteredCustomers.map((customer) => _buildCustomerItem(customer)).toList(),
    );
  }

  Widget _buildBoatsTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final filteredBoats = dataProvider.boats.where((boat) {
      return boat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (boat.ownerName ?? '').contains(_searchQuery);
    }).toList();

    return _buildTabContent(
      searchLabel: 'Tìm kiếm thuyền...',
      onAddPressed: () => _showBoatDialog(),
      emptyMessage: _searchQuery.isNotEmpty
          ? 'Không tìm thấy thuyền phù hợp'
          : 'Chưa có thuyền nào. Nhấn "Thêm mới" để tạo.',
      children: filteredBoats.map((boat) => _buildBoatItem(boat)).toList(),
    );
  }

  Widget _buildSquidTypeItem(SquidType type) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.category,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          type.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: type.description != null
            ? Text(
                type.description!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
      children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.blue,
              onPressed: () => _showSquidTypeDialog(squidType: type),  
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _deleteSquidType(type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (customer.phone != null)
              Text(
                customer.phone!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            if (customer.address != null)
              Text(
                customer.address!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.blue,
                      onPressed: () => _showCustomerDialog(customer: customer),
                    ),
                    IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
                      onPressed: () => _deleteCustomer(customer),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildBoatItem(Boat boat) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.directions_boat,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          boat.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (boat.ownerName != null)
              Text(
                'Chủ thuyền: ${boat.ownerName}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            if (boat.phone != null)
              Text(
                'SĐT: ${boat.phone}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.blue,
              onPressed: () => _showBoatDialog(boat: boat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _deleteBoat(boat),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSquidTypeDialog({SquidType? squidType}) async {
    final nameController = TextEditingController(text: squidType?.name ?? '');
    final descriptionController = TextEditingController(text: squidType?.description ?? '');

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(squidType == null ? 'Thêm loại hàng mới' : 'Sửa thông tin loại hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Tên loại hàng',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên loại hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: descriptionController,
                label: 'Mô tả',
                maxLines: 3,
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên loại hàng')),
                );
                return;
              }

              try {
                final data = {
                  'name': nameController.text,
                  'description': descriptionController.text,
                };

                if (squidType == null) {
                  await _apiService.create('squid-types', data);
                } else {
                  await _apiService.update('squid-types', squidType.id, data);
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(squidType == null ? 'Thêm loại hàng thành công' : 'Cập nhật thành công')),
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
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa loại hàng "${squidType.name}"?\nLưu ý: Việc xóa loại hàng có thể ảnh hưởng đến các giao dịch liên quan.'),
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
        await _apiService.delete('squid-types', squidType.id);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa loại hàng thành công')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')),
        );
      }
    }
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

