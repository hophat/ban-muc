import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadReportData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    try {
      final data = await _apiService.getDashboard();
      setState(() {
        _dashboardData = data;
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
            onPressed: _loadReportData,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Báo Cáo Tài Chính'),
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _showExportDialog,
            icon: Icon(Icons.download, size: 28),
            tooltip: 'Xuất báo cáo',
          ),
          IconButton(
            onPressed: _loadReportData,
            icon: Icon(Icons.refresh, size: 28),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadReportData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildKpiCards(),
                      const SizedBox(height: 30),
                      _buildDetailedStats(),
                      const SizedBox(height: 30),
                      _buildTransactionOverview(),
                      const SizedBox(height: 30),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildKpiCards() {
    final totalRevenue = (_dashboardData['total_revenue'] ?? 0).toDouble();
    final totalExpense = (_dashboardData['total_expenses'] ?? 0).toDouble();
    final profit = totalRevenue - totalExpense;
    final totalTransactions = (_dashboardData['total_purchases'] ?? 0) + (_dashboardData['total_sales'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'TỔNG QUAN TÀI CHÍNH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildKpiCard(
              'DOANH THU',
              totalRevenue,
              Icons.trending_up,
              Color(0xFF2E7D32),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard(
              'CHI PHÍ',
              totalExpense,
              Icons.trending_down,
              Color(0xFFD32F2F),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKpiCard(
              'LỢI NHUẬN',
              profit,
              Icons.account_balance_wallet,
              profit >= 0 ? Color(0xFF1565C0) : Color(0xFFD32F2F),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard(
              'GIAO DỊCH',
              totalTransactions,
              Icons.swap_horiz,
              Color(0xFFFF8F00),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, dynamic value, IconData icon, Color color) {
    final numValue = (value is int) ? value.toDouble() : (value?.toDouble() ?? 0.0);
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            title == 'GIAO DỊCH' 
                ? '${numValue.toInt()}'
                : Formatters.formatCurrency(numValue),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
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
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'THỐNG KÊ CHI TIẾT',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            'TỔNG GIAO DỊCH MUA',
            '${_dashboardData['total_purchases'] ?? 0} giao dịch',
            Icons.shopping_cart,
            Color(0xFF1565C0),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'TỔNG GIAO DỊCH BÁN',
            '${_dashboardData['total_sales'] ?? 0} giao dịch',
            Icons.sell,
            Color(0xFF2E7D32),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'SỐ LƯỢNG KHÁCH HÀNG',
            '${_dashboardData['total_customers'] ?? 0} khách hàng',
            Icons.people,
            Color(0xFFFF8F00),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'SỐ LƯỢNG GHE/TÀU',
            '${_dashboardData['total_boats'] ?? 0} ghe/tàu',
            Icons.directions_boat,
            Color(0xFF7B1FA2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionOverview() {
    final totalRevenue = (_dashboardData['total_revenue'] ?? 0).toDouble();
    final totalExpense = (_dashboardData['total_expenses'] ?? 0).toDouble();
    final profit = totalRevenue - totalExpense;
    
    return Container(
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
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'PHÂN TÍCH TÀI CHÍNH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFinancialBar('Doanh thu', totalRevenue, Color(0xFF2E7D32), totalRevenue + totalExpense),
          const SizedBox(height: 20),
          _buildFinancialBar('Chi phí', totalExpense, Color(0xFFD32F2F), totalRevenue + totalExpense),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: profit >= 0 ? Color(0xFF2E7D32) : Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      profit >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'KẾT QUẢ KINH DOANH',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatCurrency(profit),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBar(String label, double amount, Color color, double total) {
    final percentage = total > 0 ? (amount / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
            Text(
              Formatters.formatCurrency(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
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
                  color: Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'THAO TÁC NHANH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Xuất Excel',
                  Icons.download,
                  Color(0xFF2E7D32),
                  _showExportDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'In báo cáo',
                  Icons.print,
                  Color(0xFF1565C0),
                  _showPrintDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Chia sẻ',
                  Icons.share,
                  Color(0xFFFF8F00),
                  _showShareDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Tùy chỉnh',
                  Icons.tune,
                  Color(0xFF7B1FA2),
                  _showCustomizeDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Xuất báo cáo'),
          ],
        ),
        content: const Text('Xuất báo cáo tài chính ra file Excel?'),
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
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Xuất Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('In báo cáo'),
          ],
        ),
        content: const Text('Tính năng in báo cáo đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFFFF8F00)),
            SizedBox(width: 8),
            Text('Chia sẻ báo cáo'),
          ],
        ),
        content: const Text('Tính năng chia sẻ báo cáo đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showCustomizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFF7B1FA2)),
            SizedBox(width: 8),
            Text('Tùy chỉnh báo cáo'),
          ],
        ),
        content: const Text('Tính năng tùy chỉnh báo cáo đang được phát triển'),
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
