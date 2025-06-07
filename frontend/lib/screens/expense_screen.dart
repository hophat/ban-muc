import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String _filterCategory = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Filter & Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  final List<Map<String, dynamic>> _expenseCategories = [
    {'value': 'fuel', 'label': 'Nhiên liệu', 'icon': Icons.local_gas_station, 'color': Color(0xFFFF8F00)},
    {'value': 'maintenance', 'label': 'Bảo trì', 'icon': Icons.build, 'color': Color(0xFF1565C0)},
    {'value': 'equipment', 'label': 'Thiết bị', 'icon': Icons.construction, 'color': Color(0xFF2E7D32)},
    {'value': 'salary', 'label': 'Lương', 'icon': Icons.attach_money, 'color': Color(0xFF7B1FA2)},
    {'value': 'other', 'label': 'Khác', 'icon': Icons.more_horiz, 'color': Color(0xFF616161)},
  ];

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
    _loadExpenses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await _apiService.getExpenses();
      setState(() {
        _expenses = data.map((json) => Expense.fromJson(json)).toList();
        _filteredExpenses = List.from(_expenses);
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
            onPressed: _loadExpenses,
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

  void _applyFilters() {
    _filteredExpenses = _expenses.where((expense) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = expense.description.toLowerCase().contains(_searchQuery);
      }

      // Category filter
      bool matchesCategory = _filterCategory == 'all' || expense.category == _filterCategory;

      // Date filter
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = expense.expenseDate.isAfter(_startDate!) || 
                     expense.expenseDate.isAtSameMomentAs(_startDate!);
      }
      if (_endDate != null && matchesDate) {
        matchesDate = expense.expenseDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesCategory && matchesDate;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _filterCategory = 'all';
      _filteredExpenses = List.from(_expenses);
    });
  }

  Map<String, dynamic>? _getCategoryInfo(String category) {
    return _expenseCategories.firstWhere(
      (cat) => cat['value'] == category,
      orElse: () => _expenseCategories.last, // Default to 'other'
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ăn uống':
        return Icons.restaurant;
      case 'di chuyển':
        return Icons.directions_car;
      case 'mua sắm':
        return Icons.shopping_cart;
      case 'hóa đơn':
        return Icons.receipt_long;
      case 'giải trí':
        return Icons.movie;
      case 'sức khỏe':
        return Icons.medical_services;
      case 'giáo dục':
        return Icons.school;
      case 'du lịch':
        return Icons.flight;
      case 'quà tặng':
        return Icons.card_giftcard;
      case 'khác':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Quản Lý Chi Phí'),
        backgroundColor: Color(0xFFFF8F00),
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
                    Icon(Icons.download, color: Color(0xFFFF8F00)),
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
                    Icon(Icons.refresh, color: Color(0xFF2E7D32)),
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
          // Category filter chips - giữ nguyên
          Container(
            padding: const EdgeInsets.all(10),
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Tất cả', 'all', Icons.list, Color(0xFF616161)),
                const SizedBox(width: 8),
                ..._expenseCategories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    cat['label'],
                    cat['value'],
                    cat['icon'],
                    cat['color'],
                  ),
                )),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadExpenses,
                      child: _filteredExpenses.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              children: [
                                _buildSummaryStats(),
                                _buildExpensesTable(),
                                const SizedBox(height: 100), // Space for FAB
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Color(0xFFFF8F00),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add, size: 24),
        label: Text(
          'THÊM CHI PHÍ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilters() {
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
              color: Color(0xFFFF8F00),
            ),
          ),
          SizedBox(height: 16),
          
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mô tả chi phí...',
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
          
          // Date range filter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Từ ngày:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectStartDate(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF757575)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _startDate?.toString().split(' ')[0] ?? 'Chọn ngày',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      'Đến ngày:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectEndDate(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF757575)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _endDate?.toString().split(' ')[0] ?? 'Chọn ngày',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Clear filters button
          if (_searchQuery.isNotEmpty || _startDate != null || _endDate != null || _filterCategory != 'all')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all, color: Colors.white, size: 20),
                label: Text('XÓA BỘ LỌC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF757575),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
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
      initialDate: _startDate ?? DateTime.now(),
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _applyFilters();
      });
    }
  }

  Widget _buildFilterChip(String label, String value, IconData icon, Color color) {
    final isSelected = _filterCategory == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 16)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterCategory = value;
          _applyFilters();
        });
      },
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSummaryStats() {
    if (_filteredExpenses.isEmpty) return const SizedBox();
    
    final totalAmount = _filteredExpenses.fold<double>(
      0.0, (sum, expense) => sum + expense.amount
    );
    final categoryStats = <String, double>{};
    final categoryCount = <String, int>{};
    
    for (final expense in _filteredExpenses) {
      categoryStats[expense.category] = (categoryStats[expense.category] ?? 0) + expense.amount;
      categoryCount[expense.category] = (categoryCount[expense.category] ?? 0) + 1;
    }
    
    final topCategory = categoryStats.entries.isEmpty 
        ? null 
        : categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    
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
                  color: Color(0xFFFF8F00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'THỐNG KÊ CHI PHÍ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ),
              Text(
                '${_filteredExpenses.length} giao dịch',
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
                  'TỔNG CHI PHÍ',
                  Formatters.formatCurrency(totalAmount),
                  Icons.payments,
                  Color(0xFFFF8F00),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'LOẠI PHÍ NHIỀU NHẤT',
                  topCategory != null 
                      ? '${_getCategoryInfo(topCategory.key)?['label'] ?? 'N/A'}'
                      : 'N/A',
                  Icons.trending_up,
                  Color(0xFF1565C0),
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

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _startDate != null || _endDate != null || _filterCategory != 'all';
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
                size: 64,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters 
                  ? 'Không tìm thấy chi phí phù hợp'
                  : 'Chưa có chi phí nào',
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
                  : 'Nhấn nút "+" để thêm chi phí đầu tiên',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm chi phí'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8F00),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
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
        _loadExpenses();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xuất dữ liệu'),
          ],
        ),
        content: Text('Xuất ${_filteredExpenses.length} chi phí ra file Excel?'),
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
                  backgroundColor: Colors.orange,
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

  Widget _buildExpensesTable() {
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFF8F00),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('THÔNG TIN CHI PHÍ', style: _headerStyle())),
                Expanded(flex: 3, child: Text('SỐ TIỀN', style: _headerStyle())),
                Expanded(flex: 1, child: Text('', style: _headerStyle())),
              ],
            ),
          ),
          
          // Table Body
          if (_filteredExpenses.isEmpty)
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
              itemCount: _filteredExpenses.length,
              itemBuilder: (context, index) {
                final expense = _filteredExpenses[index];
                final isEven = index % 2 == 0;
                return _buildExpenseRow(expense);
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
      letterSpacing: 0.2,
    );
  }

  Widget _buildExpenseRow(Expense expense) {
    return InkWell(
      onTap: () => _showExpenseDetails(expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon và category
            Container(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8F00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: Color(0xFFFF8F00),
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Description và date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Amount
            Container(
              width: 100,
              child: Text(
                '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(expense.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF8F00),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    final categoryInfo = _getCategoryInfo(expense.category);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFF8F00)),
            SizedBox(width: 8),
            Text('Chi tiết chi phí'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Mô tả:', expense.description),
              _buildDetailRow('Loại chi phí:', categoryInfo!['label']),
              _buildDetailRow('Ngày chi:', Formatters.formatDate(expense.expenseDate)),
              _buildDetailRow('Số tiền:', Formatters.formatCurrency(expense.amount)),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                _buildDetailRow('Ghi chú:', expense.notes!),
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
              _showEditExpenseDialog(expense);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Sửa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8F00),
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

  Widget _buildExpenseCard(Expense expense) {
    final categoryInfo = _getCategoryInfo(expense.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header đơn giản  
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFFF8F00),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryInfo!['icon'],
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        categoryInfo['label'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditExpenseDialog(expense);
                        break;
                      case 'delete':
                        _showDeleteConfirmDialog(expense);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF1565C0)),
                          SizedBox(width: 12),
                          Text('Sửa', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Color(0xFFD32F2F)),
                          SizedBox(width: 12),
                          Text('Xóa', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Body với thông tin chi tiết
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'NGÀY CHI',
                        Formatters.formatDate(expense.expenseDate),
                        Icons.calendar_today,
                        Color(0xFFFF8F00),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTotalAmount(expense.amount),
                    ),
                  ],
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, size: 20, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'GHI CHÚ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expense.notes!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFF8F00),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFF8F00)),
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
                  'SỐ TIỀN',
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

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(
        title: 'Thêm chi phí mới',
        categories: _expenseCategories,
        onSaved: _loadExpenses,
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(
        title: 'Sửa chi phí',
        expense: expense,
        categories: _expenseCategories,
        onSaved: _loadExpenses,
      ),
    );
  }

  void _showDeleteConfirmDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn xóa chi phí này?'),
            const SizedBox(height: 8),
            Text(
              'Mô tả: ${expense.description}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Số tiền: ${Formatters.formatCurrency(expense.amount)}',
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
            onPressed: () => _deleteExpense(expense),
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

  Future<void> _deleteExpense(Expense expense) async {
    Navigator.pop(context); // Close dialog
    
    try {
      await _apiService.delete('expenses', expense.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa chi phí thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadExpenses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa chi phí: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ExpenseFormDialog extends StatefulWidget {
  final String title;
  final Expense? expense;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSaved;

  const ExpenseFormDialog({
    Key? key,
    required this.title,
    this.expense,
    required this.categories,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'other';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.expenseDate;
      _notesController.text = widget.expense!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi phí *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mô tả chi phí';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Loại chi phí *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: widget.categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'] as String,
                      child: Row(
                        children: [
                          Icon(category['icon'], color: category['color'], size: 20),
                          const SizedBox(width: 8),
                          Text(category['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Số tiền (₫) *',
                    border: OutlineInputBorder(),
                    // prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date field
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày chi *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(Formatters.formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes field
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.expense == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final data = {
        'expense_type': _selectedCategory,
        'amount': double.parse(_amountController.text),
        'expense_date': Formatters.toApiDate(_selectedDate),
        'notes': _descriptionController.text.trim().isEmpty 
            ? (_notesController.text.trim().isEmpty ? null : _notesController.text.trim())
            : _descriptionController.text.trim() + (_notesController.text.trim().isEmpty ? '' : '\n${_notesController.text.trim()}'),
      };

      if (widget.expense == null) {
        await apiService.create('expenses', data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm chi phí thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await apiService.update('expenses', widget.expense!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật chi phí thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu chi phí: $e'),
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
