import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase.dart';
import '../providers/data_provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Filter & Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedBoatId;
  int? _selectedSquidTypeId;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPurchases();
    _ensureMasterDataLoaded();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureMasterDataLoaded() async {
    // Use WidgetsBinding to defer execution after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.boats.isEmpty || dataProvider.squidTypes.isEmpty) {
        await dataProvider.loadMasterData();
      }
    });
  }

  Future<void> _loadPurchases() async {
    try {
      final data = await _apiService.getPurchases();
      setState(() {
        _purchases = data.map((json) => Purchase.fromJson(json)).toList();
        _filteredPurchases = List.from(_purchases);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: ${_getErrorMessage(e)}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _loadPurchases,
          ),
        ),
      );
    }
  }

  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString();
    if (errorStr.contains('SocketException') || errorStr.contains('NetworkError')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return 'Không có quyền truy cập tính năng này.';
    } else if (errorStr.contains('404')) {
      return 'Không tìm thấy dữ liệu.';
    } else if (errorStr.contains('500')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    }
    return 'Không thể tải dữ liệu. Vui lòng thử lại.';
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredPurchases = _purchases.where((purchase) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = 
          purchase.boat?.name.toLowerCase().contains(_searchQuery) == true ||
          purchase.squidType?.name.toLowerCase().contains(_searchQuery) == true ||
          purchase.notes?.toLowerCase().contains(_searchQuery) == true;
      }

      // Date filter
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = purchase.purchaseDate.isAfter(_startDate!) || 
                     purchase.purchaseDate.isAtSameMomentAs(_startDate!);
      }
      if (_endDate != null && matchesDate) {
        matchesDate = purchase.purchaseDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      // Boat filter
      bool matchesBoat = _selectedBoatId == null || purchase.boatId == _selectedBoatId;

      // Squid type filter
      bool matchesSquidType = _selectedSquidTypeId == null || purchase.squidTypeId == _selectedSquidTypeId;

      return matchesSearch && matchesDate && matchesBoat && matchesSquidType;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _selectedBoatId = null;
      _selectedSquidTypeId = null;
      _filteredPurchases = List.from(_purchases);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Quản Lý Mua Mực'),
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, size: 28),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Bộ lọc',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 28),
            tooltip: 'Tùy chọn',
            onSelected: (value) => _handleAppMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Color(0xFF1565C0)),
                    SizedBox(width: 12),
                    Text('Xuất Excel', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Text('Thống kê chi tiết', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Color(0xFFFF8F00)),
                    SizedBox(width: 12),
                    Text('Làm mới', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadPurchases,
                      child: _filteredPurchases.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              children: [
                                _buildSummaryStats(),
                                _buildPurchasesTable(),
                                const SizedBox(height: 100), // Space for FAB
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPurchaseDialog,
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add, size: 24),
        label: Text(
          'MUA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final dataProvider = Provider.of<DataProvider>(context);
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BỘ LỌC TÌM KIẾM',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
          ),
          SizedBox(height: 16),
          
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên ghe, loại mực...',
              hintStyle: TextStyle(fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Color(0xFF757575)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Color(0xFF757575)),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          
          SizedBox(height: 16),
          
          // Date range filters
          Text(
            'Khoảng thời gian:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectStartDate(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Color(0xFF757575), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startDate != null 
                                ? 'Từ: ${Formatters.formatDate(_startDate!)}'
                                : 'Từ ngày',
                            style: TextStyle(
                              fontSize: 16,
                              color: _startDate != null ? Color(0xFF424242) : Color(0xFF757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectEndDate(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Color(0xFF757575), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _endDate != null 
                                ? 'Đến: ${Formatters.formatDate(_endDate!)}'
                                : 'Đến ngày',
                            style: TextStyle(
                              fontSize: 16,
                              color: _endDate != null ? Color(0xFF424242) : Color(0xFF757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Dropdown filters
          Text(
            'Lọc theo ghe/tàu và loại mực:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedBoatId,
                  decoration: InputDecoration(
                    hintText: 'Tất cả ghe/tàu',
                    hintStyle: TextStyle(fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: TextStyle(color: Color(0xFF424242), fontSize: 16),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả ghe/tàu', style: TextStyle(fontSize: 16)),
                    ),
                    ...dataProvider.boats.map((boat) => DropdownMenuItem<int>(
                      value: boat.id,
                      child: Text(boat.name, style: TextStyle(fontSize: 16)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBoatId = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedSquidTypeId,
                  decoration: InputDecoration(
                    hintText: 'Tất cả loại mực',
                    hintStyle: TextStyle(fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: TextStyle(color: Color(0xFF424242), fontSize: 16),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả loại mực', style: TextStyle(fontSize: 16)),
                    ),
                    ...dataProvider.squidTypes.map((type) => DropdownMenuItem<int>(
                      value: type.id,
                      child: Text(type.name, style: TextStyle(fontSize: 16)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSquidTypeId = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Clear filters button
          if (_searchQuery.isNotEmpty || _startDate != null || _endDate != null || 
              _selectedBoatId != null || _selectedSquidTypeId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all, color: Colors.white, size: 20),
                label: Text('XÓA BỘ LỌC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF757575),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        _applyFilters();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _applyFilters();
      });
    }
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _startDate != null || _endDate != null || 
                      _selectedBoatId != null || _selectedSquidTypeId != null;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters 
                  ? 'Không tìm thấy giao dịch phù hợp'
                  : 'Chưa có giao dịch mua nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Thử thay đổi bộ lọc hoặc tìm kiếm với từ khóa khác'
                  : 'Nhấn nút "+" để thêm giao dịch mua mực đầu tiên',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _showAddPurchaseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm giao dịch mua'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesTable() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('THÔNG TIN GIAO DỊCH', style: _headerStyle())),
                Expanded(flex: 4, child: Text('SỐ LIỆU BÁN HÀNG', style: _headerStyle())),
                Expanded(flex: 1, child: Text('', style: _headerStyle())),
              ],
            ),
          ),
          
          // Table Body
          if (_filteredPurchases.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Không có dữ liệu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPurchases.length,
              itemBuilder: (context, index) {
                final purchase = _filteredPurchases[index];
                final isEven = index % 2 == 0;
                return _buildPurchaseRow(purchase, isEven);
              },
            ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    );
  }

  Widget _buildPurchaseRow(Purchase purchase, bool isEven) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _showPurchaseDetails(purchase),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // Combined info column (Boat + Squid Type + Date)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Boat name with icon
                    Row(
                      children: [
                        Icon(Icons.directions_boat, size: 16, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            purchase.boat?.name ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Squid type with icon
                    Row(
                      children: [
                        Icon(Icons.water_drop, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            purchase.squidType?.name ?? 'N/A',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Date with icon
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Color(0xFF757575)),
                        SizedBox(width: 6),
                        Text(
                          Formatters.formatDate(purchase.purchaseDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Notes if available
                    if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.note_alt, size: 14, color: Color(0xFFFF8F00)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              purchase.notes!.length > 40 
                                  ? '${purchase.notes!.substring(0, 40)}...'
                                  : purchase.notes!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFF8F00),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Combined data column (Weight + Unit Price + Total Amount)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Weight with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.scale, size: 14, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Text(
                          Formatters.formatWeight(purchase.weight),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Unit price with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.attach_money, size: 14, color: Color(0xFFFF8F00)),
                        SizedBox(width: 6),
                        Text(
                          '${Formatters.formatCurrency(purchase.unitPrice)}/kg',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF8F00),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Total amount with icon (highlighted)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xFF1565C0).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments, size: 16, color: Color(0xFF1565C0)),
                          SizedBox(width: 6),
                          Text(
                            Formatters.formatCurrency(purchase.totalAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions menu
              Expanded(
                flex: 1,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Color(0xFF757575), size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditPurchaseDialog(purchase);
                        break;
                      case 'delete':
                        _showDeleteConfirmDialog(purchase);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Sửa', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Chi tiết giao dịch'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Ghe/Tàu:', purchase.boat?.name ?? 'N/A'),
              _buildDetailRow('Loại mực:', purchase.squidType?.name ?? 'N/A'),
              _buildDetailRow('Ngày mua:', Formatters.formatDate(purchase.purchaseDate)),
              _buildDetailRow('Khối lượng:', Formatters.formatWeight(purchase.weight)),
              _buildDetailRow('Đơn giá:', '${Formatters.formatCurrency(purchase.unitPrice)}/kg'),
              _buildDetailRow('Tổng tiền:', Formatters.formatCurrency(purchase.totalAmount)),
              if (purchase.notes != null && purchase.notes!.isNotEmpty)
                _buildDetailRow('Ghi chú:', purchase.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditPurchaseDialog(purchase);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Sửa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1565C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TỔNG TIỀN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPurchaseDialog() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Check if data is still loading
    if (dataProvider.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải dữ liệu, vui lòng chờ...'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    // Ensure master data is loaded
    if (dataProvider.boats.isEmpty || dataProvider.squidTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải dữ liệu ghe/tàu và loại mực...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await dataProvider.loadMasterData();
      
      // Check again after loading
      if (dataProvider.boats.isEmpty || dataProvider.squidTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải dữ liệu. Vui lòng kiểm tra kết nối mạng.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseFormScreen(
          title: 'Thêm giao dịch mua mực',
          onSaved: _loadPurchases,
        ),
      ),
    );
  }

  void _showEditPurchaseDialog(Purchase purchase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseFormScreen(
          title: 'Sửa giao dịch mua mực',
          purchase: purchase,
          onSaved: _loadPurchases,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn xóa giao dịch này?'),
            const SizedBox(height: 8),
            Text(
              'Ghe: ${purchase.boat?.name}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Loại mực: ${purchase.squidType?.name}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Tổng tiền: ${Formatters.formatCurrency(purchase.totalAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _deletePurchase(purchase),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePurchase(Purchase purchase) async {
    Navigator.pop(context); // Close dialog
    
    try {
      await _apiService.delete('purchases', purchase.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa giao dịch thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPurchases();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa giao dịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryStats() {
    if (_filteredPurchases.isEmpty) return const SizedBox();
    
    final totalAmount = _filteredPurchases.fold<double>(
      0.0, (sum, purchase) => sum + purchase.totalAmount
    );
    final totalWeight = _filteredPurchases.fold<double>(
      0.0, (sum, purchase) => sum + purchase.weight
    );
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0.0;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'THỐNG KÊ TỔNG QUAN',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              Text(
                '${_filteredPurchases.length} giao dịch',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'TỔNG TIỀN',
                  Formatters.formatCurrency(totalAmount),
                  Icons.payments,
                  Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'TỔNG KHỐI LƯỢNG',
                  Formatters.formatWeight(totalWeight),
                  Icons.scale,
                  Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'GIÁ TRUNG BÌNH',
                  '${Formatters.formatCurrency(avgPrice)}/kg',
                  Icons.trending_up,
                  Color(0xFFFF8F00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleAppMenuAction(String value) {
    switch (value) {
      case 'export':
        _showExportDialog();
        break;
      case 'stats':
        _showDetailedStats();
        break;
      case 'refresh':
        _loadPurchases();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Xuất dữ liệu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Xuất ${_filteredPurchases.length} giao dịch mua mực ra file Excel?'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File sẽ chứa thông tin chi tiết về từng giao dịch',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToExcel();
            },
            icon: const Icon(Icons.download),
            label: const Text('Xuất Excel'),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() {
    // Simulate export process
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white),
            const SizedBox(width: 8),
            Text('Đang xuất ${_filteredPurchases.length} giao dịch...'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate export delay
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Xuất file thành công!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showDetailedStats() {
    if (_filteredPurchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có dữ liệu để hiển thị thống kê'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalAmount = _filteredPurchases.fold<double>(0.0, (sum, p) => sum + p.totalAmount);
    final totalWeight = _filteredPurchases.fold<double>(0.0, (sum, p) => sum + p.weight);
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0.0;
    
    // Group by boat
    final boatStats = <String, Map<String, dynamic>>{};
    for (final purchase in _filteredPurchases) {
      final boatName = purchase.boat?.name ?? 'Không xác định';
      if (!boatStats.containsKey(boatName)) {
        boatStats[boatName] = {'count': 0, 'amount': 0.0, 'weight': 0.0};
      }
      boatStats[boatName]!['count'] += 1;
      boatStats[boatName]!['amount'] += purchase.totalAmount;
      boatStats[boatName]!['weight'] += purchase.weight;
    }

    // Group by squid type
    final squidStats = <String, Map<String, dynamic>>{};
    for (final purchase in _filteredPurchases) {
      final squidName = purchase.squidType?.name ?? 'Không xác định';
      if (!squidStats.containsKey(squidName)) {
        squidStats[squidName] = {'count': 0, 'amount': 0.0, 'weight': 0.0};
      }
      squidStats[squidName]!['count'] += 1;
      squidStats[squidName]!['amount'] += purchase.totalAmount;
      squidStats[squidName]!['weight'] += purchase.weight;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Thống kê chi tiết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Overall stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Số giao dịch: ${_filteredPurchases.length}'),
                    Text('Tổng tiền: ${Formatters.formatCurrency(totalAmount)}'),
                    Text('Tổng khối lượng: ${Formatters.formatWeight(totalWeight)}'),
                    Text('Giá trung bình: ${Formatters.formatCurrency(avgPrice)}/kg'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Theo ghe/tàu'),
                          Tab(text: 'Theo loại mực'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStatsTable(boatStats),
                            _buildStatsTable(squidStats),
                          ],
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
    );
  }

  Widget _buildStatsTable(Map<String, Map<String, dynamic>> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: stats.entries.map((entry) {
        final name = entry.key;
        final data = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['count']} giao dịch'),
                Text('${Formatters.formatCurrency(data['amount'])}'),
                Text('${Formatters.formatWeight(data['weight'])}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PurchaseFormScreen extends StatefulWidget {
  final String title;
  final Purchase? purchase;
  final VoidCallback onSaved;

  const PurchaseFormScreen({
    Key? key,
    required this.title,
    this.purchase,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedBoatId;
  int? _selectedSquidTypeId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      _selectedBoatId = widget.purchase!.boatId;
      _selectedSquidTypeId = widget.purchase!.squidTypeId;
      _weightController.text = widget.purchase!.weight.toString();
      _unitPriceController.text = widget.purchase!.unitPrice.toString();
      _selectedDate = widget.purchase!.purchaseDate;
      _notesController.text = widget.purchase!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, size: 28),
        ),
        actions: [
          if (widget.purchase == null)
            IconButton(
              onPressed: _showQuickAddBoatDialog,
              icon: Icon(Icons.add_circle, size: 28),
              tooltip: 'Thêm ghe/tàu nhanh',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boat dropdown with quick add
              Text(
                'CHỌN GHE/TÀU *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      value: _selectedBoatId,
                      style: TextStyle(fontSize: 18, color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        hintText: 'Chọn ghe/tàu',
                        hintStyle: TextStyle(fontSize: 16),
                        prefixIcon: Icon(Icons.directions_boat, size: 28, color: Color(0xFF1565C0)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                        ),
                      ),
                      items: dataProvider.boats.map((boat) {
                        return DropdownMenuItem(
                          value: boat.id,
                          child: Text('${boat.name} - ${boat.ownerName}', style: TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBoatId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn ghe/tàu';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _showQuickAddBoatDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: Size(60, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Icon(Icons.add, size: 24),
                  ),
                ],
              ),
              SizedBox(height: 24),

                      // Squid type dropdown with quick add
              Text(
                'LOẠI MỰC *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      value: _selectedSquidTypeId,
                      style: TextStyle(fontSize: 18, color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        hintText: 'Chọn loại mực',
                        hintStyle: TextStyle(fontSize: 16),
                        prefixIcon: Icon(Icons.water_drop, size: 28, color: Color(0xFF2E7D32)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                        ),
                      ),
                      items: dataProvider.squidTypes.map((type) {
                        return DropdownMenuItem(
                          value: type.id,
                          child: Text(type.name, style: TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSquidTypeId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn loại mực';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _showQuickAddSquidTypeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      minimumSize: Size(60, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Icon(Icons.add, size: 24),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Weight and Price in row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KHỐI LƯỢNG (KG) *',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Nhập KL',
                            hintStyle: TextStyle(fontSize: 16),
                            prefixIcon: Icon(Icons.scale, size: 28, color: Color(0xFF2E7D32)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập khối lượng';
                            }
                            if (double.tryParse(value) == null || double.parse(value) <= 0) {
                              return 'Khối lượng phải lớn hơn 0';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {}); // Trigger rebuild to update total
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐƠN GIÁ (₫/KG) *',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _unitPriceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Nhập giá',
                            hintStyle: TextStyle(fontSize: 16),
                            prefixIcon: Icon(Icons.attach_money, size: 28, color: Color(0xFFFF8F00)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập đơn giá';
                            }
                            if (double.tryParse(value) == null || double.parse(value) <= 0) {
                              return 'Đơn giá phải lớn hơn 0';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {}); // Trigger rebuild to update total
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Total amount display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1565C0).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments, color: Colors.white, size: 36),
                        SizedBox(width: 16),
                        Text(
                          'TỔNG TIỀN THANH TOÁN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _calculateTotal(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Date field
              Text(
                'NGÀY MUA *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 28, color: Color(0xFF1565C0)),
                      SizedBox(width: 16),
                      Text(
                        Formatters.formatDate(_selectedDate),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_drop_down, size: 28, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Notes field
              Text(
                'GHI CHÚ (TÙY CHỌN)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú về giao dịch (nếu có)',
                  hintStyle: TextStyle(fontSize: 16),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.note_alt, size: 28, color: Color(0xFF757575)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 60),
                    side: BorderSide(color: Color(0xFF757575), width: 2),
                    foregroundColor: Color(0xFF757575),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('HỦY BỎ'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePurchase,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 60),
                    backgroundColor: Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.purchase == null ? 'THÊM GIAO DỊCH' : 'CẬP NHẬT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTotal() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final total = weight * unitPrice;
    return Formatters.formatCurrency(total);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _showQuickAddBoatDialog() {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_boat, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Thêm Ghe/Tàu Nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÊN GHE/TÀU *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên ghe/tàu',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.directions_boat, size: 24, color: Color(0xFF2E7D32)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên ghe/tàu';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'TÊN CHỦ GHE/TÀU *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: ownerController,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên chủ ghe/tàu',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.person, size: 24, color: Color(0xFF2E7D32)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên chủ ghe/tàu';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'HỦY',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() {
                    isLoading = true;
                  });

                  try {
                    final apiService = ApiService();
                    final boatData = {
                      'name': nameController.text.trim(),
                      'owner_name': ownerController.text.trim(),
                    };

                    final response = await apiService.create('boats', boatData);
                    
                    // Reload boats data
                    final dataProvider = Provider.of<DataProvider>(context, listen: false);
                    await dataProvider.loadBoats();

                    // Select the newly created boat
                    setState(() {
                      _selectedBoatId = response['id'];
                    });

                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Thêm ghe/tàu "${nameController.text.trim()}" thành công'),
                          ],
                        ),
                        backgroundColor: Color(0xFF2E7D32),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi thêm ghe/tàu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('THÊM'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddSquidTypeDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.water_drop, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Thêm Loại Mực Nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÊN LOẠI MỰC *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'VD: Mực ống, Mực nang, Mực lá...',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.water_drop, size: 24, color: Color(0xFF1565C0)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên loại mực';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'MÔ TẢ (TÙY CHỌN)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nhập mô tả về loại mực này (tùy chọn)',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description, size: 24, color: Color(0xFF1565C0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'HỦY',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() {
                    isLoading = true;
                  });

                  try {
                    final apiService = ApiService();
                    final squidTypeData = {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty 
                          ? null 
                          : descriptionController.text.trim(),
                    };

                    final response = await apiService.create('squid-types', squidTypeData);
                    
                    // Reload squid types data
                    final dataProvider = Provider.of<DataProvider>(context, listen: false);
                    await dataProvider.loadSquidTypes();

                    // Select the newly created squid type
                    setState(() {
                      _selectedSquidTypeId = response['id'];
                    });

                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Thêm loại mực "${nameController.text.trim()}" thành công'),
                          ],
                        ),
                        backgroundColor: Color(0xFF1565C0),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi thêm loại mực: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('THÊM'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final data = {
        'boat_id': _selectedBoatId,
        'squid_type_id': _selectedSquidTypeId,
        'weight': double.parse(_weightController.text),
        'unit_price': double.parse(_unitPriceController.text),
        'purchase_date': Formatters.toApiDate(_selectedDate),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      if (widget.purchase == null) {
        await apiService.create('purchases', data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm giao dịch mua thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await apiService.update('purchases', widget.purchase!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật giao dịch mua thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu giao dịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 