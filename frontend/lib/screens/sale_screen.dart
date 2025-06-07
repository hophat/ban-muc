import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../providers/data_provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({Key? key}) : super(key: key);

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Filter & Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCustomerId;
  int? _selectedSquidTypeId;
  String? _selectedPaymentStatus;
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
    _loadSales();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.customers.isEmpty || dataProvider.squidTypes.isEmpty) {
        await dataProvider.loadMasterData();
      }
    });
  }

  Future<void> _loadSales() async {
    try {
      final data = await _apiService.getSales();
      setState(() {
        _sales = data.map((json) => Sale.fromJson(json)).toList();
        _filteredSales = List.from(_sales);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _loadSales,
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
    _filteredSales = _sales.where((sale) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = 
          sale.customer?.name.toLowerCase().contains(_searchQuery) == true ||
          sale.squidType?.name.toLowerCase().contains(_searchQuery) == true;
      }

      // Date filter
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = sale.saleDate.isAfter(_startDate!) || 
                     sale.saleDate.isAtSameMomentAs(_startDate!);
      }
      if (_endDate != null && matchesDate) {
        matchesDate = sale.saleDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      // Customer filter
      bool matchesCustomer = _selectedCustomerId == null || sale.customerId == _selectedCustomerId;

      // Squid type filter
      bool matchesSquidType = _selectedSquidTypeId == null || sale.squidTypeId == _selectedSquidTypeId;

      // Payment status filter
      bool matchesPaymentStatus = _selectedPaymentStatus == null || sale.paymentStatus == _selectedPaymentStatus;

      return matchesSearch && matchesDate && matchesCustomer && matchesSquidType && matchesPaymentStatus;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _selectedCustomerId = null;
      _selectedSquidTypeId = null;
      _selectedPaymentStatus = null;
      _filteredSales = List.from(_sales);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Quản Lý Bán Mực'),
        backgroundColor: Color(0xFF2E7D32),
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
                    Icon(Icons.download, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Text('Xuất Excel', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Color(0xFF1565C0)),
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
                      onRefresh: _loadSales,
                      child: _filteredSales.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              children: [
                                _buildSummaryStats(),
                                _buildSalesTable(),
                                const SizedBox(height: 100), // Space for FAB
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSaleDialog,
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add, size: 24),
        label: Text(
          'BÁN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final dataProvider = Provider.of<DataProvider>(context);
    
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
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
              color: Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên khách hàng, loại mực...',
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
          
          SizedBox(height: 16),
          
          Text(
            'Trạng thái thanh toán:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPaymentStatus,
            decoration: InputDecoration(
              hintText: 'Tất cả trạng thái',
              hintStyle: TextStyle(fontSize: 14),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            style: TextStyle(color: Color(0xFF424242), fontSize: 16),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Tất cả trạng thái', style: TextStyle(fontSize: 16)),
              ),
              DropdownMenuItem<String>(
                value: 'paid',
                child: Text('Đã thanh toán', style: TextStyle(fontSize: 16)),
              ),
              DropdownMenuItem<String>(
                value: 'unpaid',
                child: Text('Chưa thanh toán', style: TextStyle(fontSize: 16)),
              ),
              DropdownMenuItem<String>(
                value: 'partial',
                child: Text('Thanh toán một phần', style: TextStyle(fontSize: 16)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentStatus = value;
                _applyFilters();
              });
            },
          ),
          
          SizedBox(height: 16),
          
          if (_searchQuery.isNotEmpty || _startDate != null || _endDate != null || 
              _selectedCustomerId != null || _selectedSquidTypeId != null || _selectedPaymentStatus != null)
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

  Widget _buildSummaryStats() {
    if (_filteredSales.isEmpty) return const SizedBox();
    
    final totalAmount = _filteredSales.fold<double>(
      0.0, (sum, sale) => sum + sale.totalAmount
    );
    final totalWeight = _filteredSales.fold<double>(
      0.0, (sum, sale) => sum + sale.weight
    );
    final paidCount = _filteredSales.where((sale) => sale.paymentStatus == 'paid').length;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0.0;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(10),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'THỐNG KÊ BÁN MỰC',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Text(
                '${_filteredSales.length} giao dịch',
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
                  'TỔNG DOANH THU',
                  Formatters.formatCurrency(totalAmount),
                  Icons.payments,
                  Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'TỔNG KHỐI LƯỢNG',
                  Formatters.formatWeight(totalWeight),
                  Icons.scale,
                  Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ĐÃ THANH TOÁN',
                  '$paidCount/${_filteredSales.length}',
                  Icons.check_circle,
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
      padding: const EdgeInsets.all(10),
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

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _startDate != null || _endDate != null || 
                      _selectedCustomerId != null || _selectedSquidTypeId != null || _selectedPaymentStatus != null;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.sell_outlined,
                size: 64,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters 
                  ? 'Không tìm thấy giao dịch phù hợp'
                  : 'Chưa có giao dịch bán nào',
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
                  : 'Nhấn nút "+" để thêm giao dịch bán mực đầu tiên',
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTable() {
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
              color: Color(0xFF2E7D32),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('THÔNG TIN GIAO DỊCH', style: _headerStyle())),
                Expanded(flex: 5, child: Text('SỐ LIỆU BÁN HÀNG', style: _headerStyle())),
              ],
            ),
          ),
          
          // Table Body
          if (_filteredSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
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
              itemCount: _filteredSales.length,
              itemBuilder: (context, index) {
                final sale = _filteredSales[index];
                final isEven = index % 2 == 0;
                return _buildSaleRow(sale, isEven);
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

  Widget _buildSaleRow(Sale sale, bool isEven) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // Combined info column (Customer + Squid Type + Date)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer name with icon
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sale.customer?.name ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sale.customer?.phone != null && sale.customer!.phone!.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Color(0xFF757575)),
                          SizedBox(width: 6),
                          Text(
                            sale.customer!.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 4),
                    // Squid type with icon
                    Row(
                      children: [
                        Icon(Icons.water_drop, size: 16, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sale.squidType?.name ?? 'N/A',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1565C0),
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
                          Formatters.formatDate(sale.saleDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Combined data column (Weight + Unit Price + Total Amount + Payment Status)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Weight with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.scale, size: 14, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Text(
                          Formatters.formatWeight(sale.weight),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
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
                          '${Formatters.formatCurrency(sale.unitPrice)}/kg',
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
                        color: Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments, size: 16, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            Formatters.formatCurrency(sale.totalAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    // Payment status with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(sale.paymentStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentStatusIcon(sale.paymentStatus),
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            Formatters.getPaymentStatusText(sale.paymentStatus),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
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
              _buildDetailRow('Khách hàng:', sale.customer?.name ?? 'N/A'),
              _buildDetailRow('Loại mực:', sale.squidType?.name ?? 'N/A'),
              _buildDetailRow('Ngày bán:', Formatters.formatDate(sale.saleDate)),
              _buildDetailRow('Khối lượng:', Formatters.formatWeight(sale.weight)),
              _buildDetailRow('Đơn giá:', '${Formatters.formatCurrency(sale.unitPrice)}/kg'),
              _buildDetailRow('Tổng tiền:', Formatters.formatCurrency(sale.totalAmount)),
              _buildDetailRow('Thanh toán:', Formatters.getPaymentStatusText(sale.paymentStatus)),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                _buildDetailRow('Ghi chú:', sale.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Color(0xFF2E7D32);
      case 'unpaid':
        return Color(0xFFD32F2F);
      case 'partial':
        return Color(0xFFFF8F00);
      default:
        return Color(0xFF757575);
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.pending;
      case 'partial':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  void _showAddSaleDialog() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Check if data is still loading
    if (dataProvider.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải dữ liệu, vui lòng chờ...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Ensure master data is loaded
    if (dataProvider.customers.isEmpty || dataProvider.squidTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải dữ liệu khách hàng và loại mực...'),
          backgroundColor: Colors.orange,
        ),
      );
      
      await dataProvider.loadMasterData();
      
      // Check again after loading
      if (dataProvider.customers.isEmpty || dataProvider.squidTypes.isEmpty) {
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
        builder: (context) => SaleFormScreen(
          title: 'Thêm giao dịch bán mực',
          onSaved: _loadSales,
        ),
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
        _loadSales();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('Xuất dữ liệu'),
          ],
        ),
        content: Text('Xuất ${_filteredSales.length} giao dịch bán mực ra file Excel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng xuất Excel đang được phát triển'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Xuất Excel'),
          ),
        ],
      ),
    );
  }

  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thống kê chi tiết'),
        content: const Text('Tính năng thống kê chi tiết đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class SaleFormScreen extends StatefulWidget {
  final String title;
  final Sale? sale;
  final VoidCallback onSaved;

  const SaleFormScreen({
    Key? key,
    required this.title,
    this.sale,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedCustomerId;
  int? _selectedSquidTypeId;
  DateTime _selectedDate = DateTime.now();
  String _paymentStatus = 'unpaid';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sale != null) {
      _selectedCustomerId = widget.sale!.customerId;
      _selectedSquidTypeId = widget.sale!.squidTypeId;
      _weightController.text = widget.sale!.weight.toString();
      _unitPriceController.text = widget.sale!.unitPrice.toString();
      _selectedDate = widget.sale!.saleDate;
      _paymentStatus = widget.sale!.paymentStatus;
      _notesController.text = widget.sale!.notes ?? '';
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
        backgroundColor: Color(0xFF2E7D32),
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
          if (widget.sale == null)
            IconButton(
              onPressed: _showQuickAddCustomerDialog,
              icon: Icon(Icons.add_circle, size: 28),
              tooltip: 'Thêm khách hàng nhanh',
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
              // Customer dropdown with quick add
              Text(
                'CHỌN KHÁCH HÀNG *',
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
                      value: _selectedCustomerId,
                      style: TextStyle(fontSize: 18, color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        hintText: 'Chọn khách hàng',
                        hintStyle: TextStyle(fontSize: 16),
                        prefixIcon: Icon(Icons.person, size: 28, color: Color(0xFF2E7D32)),
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
                          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                        ),
                      ),
                      items: dataProvider.customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text('${customer.name}${customer.phone != null ? ' - ${customer.phone}' : ''}', style: TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn khách hàng';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _showQuickAddCustomerDialog,
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
                        prefixIcon: Icon(Icons.water_drop, size: 28, color: Color(0xFF1565C0)),
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
                          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                            prefixIcon: Icon(Icons.scale, size: 28, color: Color(0xFF1565C0)),
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
                              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2E7D32).withOpacity(0.3),
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

              // Payment status
              Text(
                'TRẠNG THÁI THANH TOÁN *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                style: TextStyle(fontSize: 18, color: Color(0xFF424242)),
                decoration: InputDecoration(
                  hintText: 'Chọn trạng thái thanh toán',
                  hintStyle: TextStyle(fontSize: 16),
                  prefixIcon: Icon(Icons.payment, size: 28, color: Color(0xFF2E7D32)),
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
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'paid',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                        SizedBox(width: 8),
                        Text('Đã thanh toán', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'unpaid',
                    child: Row(
                      children: [
                        Icon(Icons.pending, color: Color(0xFFD32F2F), size: 20),
                        SizedBox(width: 8),
                        Text('Chưa thanh toán', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                                     DropdownMenuItem(
                     value: 'partial',
                     child: Row(
                       children: [
                         Icon(Icons.schedule, color: Color(0xFFFF8F00), size: 20),
                         SizedBox(width: 8),
                         Text('Thanh toán một phần', style: TextStyle(fontSize: 18)),
                       ],
                     ),
                   ),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value!;
                  });
                },
              ),
              SizedBox(height: 24),

              // Date field
              Text(
                'NGÀY BÁN *',
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
                      Icon(Icons.calendar_today, size: 28, color: Color(0xFF2E7D32)),
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
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                  onPressed: _isLoading ? null : _saveSale,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 60),
                    backgroundColor: Color(0xFF2E7D32),
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
                      : Text(widget.sale == null ? 'THÊM GIAO DỊCH' : 'CẬP NHẬT'),
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

  void _showQuickAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
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
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Thêm Khách Hàng Nhanh',
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
                    'TÊN KHÁCH HÀNG *',
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
                      hintText: 'Nhập tên khách hàng',
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
                        return 'Vui lòng nhập tên khách hàng';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'SỐ ĐIỆN THOẠI (TÙY CHỌN)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.phone, size: 24, color: Color(0xFF2E7D32)),
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
                    final customerData = {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim().isEmpty 
                          ? null 
                          : phoneController.text.trim(),
                    };

                    final response = await apiService.create('customers', customerData);
                    
                    // Reload customers data
                    final dataProvider = Provider.of<DataProvider>(context, listen: false);
                    await dataProvider.loadCustomers();

                    // Select the newly created customer
                    setState(() {
                      _selectedCustomerId = response['id'];
                    });

                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Thêm khách hàng "${nameController.text.trim()}" thành công'),
                          ],
                        ),
                        backgroundColor: Color(0xFF2E7D32),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi thêm khách hàng: $e'),
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

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final data = {
        'customer_id': _selectedCustomerId,
        'squid_type_id': _selectedSquidTypeId,
        'weight': double.parse(_weightController.text),
        'unit_price': double.parse(_unitPriceController.text),
        'sale_date': Formatters.toApiDate(_selectedDate),
        'payment_status': _paymentStatus,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      if (widget.sale == null) {
        await apiService.create('sales', data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm giao dịch bán thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await apiService.update('sales', widget.sale!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật giao dịch bán thành công'),
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