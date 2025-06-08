import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String _selectedReportType = 'daily'; // daily, weekly, monthly
  String _selectedChartType = 'amount'; // amount, quantity
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // Định nghĩa các tháng bằng tiếng Việt
  final List<String> _vietnameseMonths = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];

  // Định nghĩa các ngày trong tuần bằng tiếng Việt
  final List<String> _vietnameseWeekdays = [
    'Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'
  ];

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMonth(DateTime date) {
    return '${_vietnameseMonths[date.month - 1]} ${date.year}';
  }

  String _formatWeek(DateTime date) {
    final weekNumber = date.day ~/ 7 + 1;
    return 'Tuần $weekNumber - ${_vietnameseMonths[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Tổng quan',
              iconMargin: EdgeInsets.only(bottom: 8),
            ),
            Tab(
              icon: Icon(Icons.table_chart_outlined),
              text: 'Chi tiết',
              iconMargin: EdgeInsets.only(bottom: 8),
          ),
        ],
      ),
      ),
      body: Column(
                    children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDetailTab(),
                    ],
                  ),
                ),
        ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
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
      child: Column(
            children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Từ ngày',
                  controller: TextEditingController(
                    text: _formatDate(_startDate),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(true),
                  suffixIcon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Đến ngày',
                  controller: TextEditingController(
                    text: _formatDate(_endDate),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(false),
                  suffixIcon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        Row(
          children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: InputDecoration(
                    labelText: 'Loại báo cáo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Theo ngày')),
                    DropdownMenuItem(value: 'weekly', child: Text('Theo tuần')),
                    DropdownMenuItem(value: 'monthly', child: Text('Theo tháng')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedReportType = value);
                    }
                  },
                ),
              ),
            const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChartType,
                  decoration: InputDecoration(
                    labelText: 'Loại biểu đồ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'amount', child: Text('Theo tiền')),
                    DropdownMenuItem(value: 'quantity', child: Text('Theo số lượng')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedChartType = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final purchases = dataProvider.purchases.where((p) => 
      p.createdAt.isAfter(_startDate) && p.createdAt.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();
    final sales = dataProvider.sales.where((s) => 
      s.createdAt.isAfter(_startDate) && s.createdAt.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final totalPurchaseAmount = purchases.fold<double>(0, (sum, p) => sum + p.totalAmount);
    final totalSaleAmount = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalPurchaseQuantity = purchases.fold<double>(0, (sum, p) => sum + p.weight);
    final totalSaleQuantity = sales.fold<double>(0, (sum, s) => sum + s.weight);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(
            totalPurchaseAmount,
            totalSaleAmount,
            totalPurchaseQuantity,
            totalSaleQuantity,
          ),
          const SizedBox(height: 24),
          _buildChart(purchases, sales),
          const SizedBox(height: 24),
          _buildTopItems(purchases, sales),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    double totalPurchaseAmount,
    double totalSaleAmount,
    double totalPurchaseQuantity,
    double totalSaleQuantity,
  ) {
    // Tính toán lợi nhuận
    final profit = totalSaleAmount - totalPurchaseAmount; // Lợi nhuận = Bán - Mua
    final profitMargin = totalPurchaseAmount > 0 ? (profit / totalPurchaseAmount * 100) : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Tổng mua',
          _currencyFormat.format(totalPurchaseAmount),
          '${totalPurchaseQuantity.toStringAsFixed(1)} kg',
          Colors.blue,
        ),
        _buildSummaryCard(
          'Tổng bán',
          _currencyFormat.format(totalSaleAmount),
          '${totalSaleQuantity.toStringAsFixed(1)} kg',
          Colors.green,
        ),
        _buildSummaryCard(
          'Chênh lệch số lượng',
          '${(totalSaleQuantity - totalPurchaseQuantity).toStringAsFixed(1)} kg',
          '${((totalSaleQuantity - totalPurchaseQuantity) / totalPurchaseQuantity * 100).toStringAsFixed(1)}%',
          Colors.orange,
        ),
        _buildSummaryCard(
          'Lợi nhuận',
          _currencyFormat.format(profit),
          profit >= 0 
              ? '${profitMargin.toStringAsFixed(1)}% lãi'
              : '${(-profitMargin).toStringAsFixed(1)}% lỗ',
          profit >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Purchase> purchases, List<Sale> sales) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu đồ ${_selectedChartType == 'amount' ? 'doanh thu' : 'số lượng'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
              Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _selectedChartType == 'amount'
                              ? _currencyFormat.format(value)
                              : value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        String label;
                        switch (_selectedReportType) {
                          case 'daily':
                            label = _formatDate(date);
                            break;
                          case 'weekly':
                            label = _formatWeek(date);
                            break;
                          case 'monthly':
                            label = _formatMonth(date);
                            break;
                          default:
                            label = '';
                        }
                        return Text(label, style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  _createLineChartBarData(purchases, Colors.blue, 'Mua'),
                  _createLineChartBarData(sales, Colors.green, 'Bán'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _createLineChartBarData(List<dynamic> data, Color color, String label) {
    final spots = _getChartSpots(data);
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<dynamic> data) {
    final Map<DateTime, double> aggregatedData = {};
    
    for (var item in data) {
      DateTime key;
      switch (_selectedReportType) {
        case 'daily':
          key = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
          break;
        case 'weekly':
          final weekNumber = item.createdAt.day ~/ 7;
          key = DateTime(item.createdAt.year, item.createdAt.month, weekNumber * 7 + 1);
          break;
        case 'monthly':
          key = DateTime(item.createdAt.year, item.createdAt.month);
          break;
        default:
          key = item.createdAt;
      }

      final value = _selectedChartType == 'amount' ? item.totalAmount : item.weight;
      aggregatedData[key] = (aggregatedData[key] ?? 0) + value;
    }

    return aggregatedData.entries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value,
      );
    }).toList();
  }

  Widget _buildTopItems(List<Purchase> purchases, List<Sale> sales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top mặt hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          ),
          const SizedBox(height: 16),
        Container(
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
          child: Column(
            children: [
              _buildTopItemsTable(purchases, sales, 'Mua'),
              const Divider(height: 1),
              _buildTopItemsTable(sales, purchases, 'Bán'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopItemsTable(List<dynamic> data, List<dynamic> otherData, String type) {
    final Map<String, double> itemStats = {};
    for (var item in data) {
      final name = item.squidType.name;
      final amount = item.totalAmount;
      final quantity = item.weight;
      itemStats[name] = (itemStats[name] ?? 0) + (_selectedChartType == 'amount' ? amount : quantity);
    }

    final sortedItems = itemStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top $type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: type == 'Mua' ? Colors.blue : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedItems.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
          Expanded(
                    flex: 1,
            child: Text(
                      _selectedChartType == 'amount'
                          ? _currencyFormat.format(entry.value)
                          : '${entry.value.toStringAsFixed(1)} kg',
              style: TextStyle(
                        fontSize: 14,
                fontWeight: FontWeight.w500,
                        color: type == 'Mua' ? Colors.blue : Colors.green,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    final dataProvider = Provider.of<DataProvider>(context);
    final purchases = dataProvider.purchases.where((p) => 
      p.createdAt.isAfter(_startDate) && p.createdAt.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();
    final sales = dataProvider.sales.where((s) => 
      s.createdAt.isAfter(_startDate) && s.createdAt.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    // Tính toán tổng chi phí và lợi nhuận
    final totalPurchaseAmount = purchases.fold<double>(0, (sum, p) => sum + p.totalAmount);
    final totalPurchaseQuantity = purchases.fold<double>(0, (sum, p) => sum + p.weight);
    final totalSaleAmount = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalSaleQuantity = sales.fold<double>(0, (sum, s) => sum + s.weight);
    final profit = totalSaleAmount - totalPurchaseAmount; // Lợi nhuận = Bán - Mua
    final profitMargin = (profit / totalPurchaseAmount) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                const Text(
                  'Tổng kết doanh thu và lợi nhuận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCostSummaryRow('Tổng chi phí mua hàng:', totalPurchaseAmount),
                _buildCostSummaryRow('Số lượng mua:', totalPurchaseQuantity, isQuantity: true),
                const Divider(height: 24),
                _buildCostSummaryRow('Tổng doanh thu bán:', totalSaleAmount),
                _buildCostSummaryRow('Số lượng bán:', totalSaleQuantity, isQuantity: true),
                _buildCostSummaryRow(
                  'Chênh lệch số lượng:',
                  totalSaleQuantity - totalPurchaseQuantity,
                  isQuantity: true,
                ),
                const Divider(height: 24),
                _buildCostSummaryRow(
                  'Lợi nhuận:',
                  profit,
                  isProfit: true,
                ),
                _buildCostSummaryRow(
                  'Tỷ suất lợi nhuận:',
                  profitMargin,
                  isPercentage: true,
                  isProfit: true,
                ),
                const SizedBox(height: 8),
                    Text(
                  profit >= 0 
                      ? 'Lãi ${profitMargin.toStringAsFixed(1)}% so với chi phí mua'
                      : 'Lỗ ${(-profitMargin).toStringAsFixed(1)}% so với chi phí mua',
                      style: TextStyle(
                    fontSize: 14,
                    color: profit >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 24),
          _buildTransactionTable('Giao dịch mua', purchases),
          const SizedBox(height: 24),
          _buildTransactionTable('Giao dịch bán', sales),
        ],
      ),
    );
  }

  Widget _buildCostSummaryRow(String label, double value, {
    bool isProfit = false, 
    bool isPercentage = false,
    bool isQuantity = false,
  }) {
    Color getColor() {
      if (!isProfit) return Colors.grey.shade800;
      if (isPercentage) {
        return value >= 0 ? Colors.green : Colors.red;
      }
      return value >= 0 ? Colors.green : Colors.red;
    }

    final color = getColor();
    
    String getFormattedValue() {
      if (isPercentage) {
        return '${value.toStringAsFixed(1)}%';
      }
      if (isQuantity) {
        return '${value.toStringAsFixed(1)} kg';
      }
      return _currencyFormat.format(value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              ),
            ),
            Text(
            getFormattedValue(),
              style: TextStyle(
              fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildTransactionTable(String title, List<dynamic> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Ngày')),
                const DataColumn(label: Text('Loại hàng')),
                const DataColumn(label: Text('Số lượng')),
                const DataColumn(label: Text('Đơn giá')),
                const DataColumn(label: Text('Thành tiền')),
                const DataColumn(label: Text('Ghi chú')),
                DataColumn(
                  label: Row(
        children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Thao tác', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
              rows: transactions.map((transaction) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(transaction.createdAt))),
                    DataCell(Text(transaction.squidType.name)),
                    DataCell(Text('${transaction.weight.toStringAsFixed(1)} kg')),
                    DataCell(Text(_currencyFormat.format(transaction.unitPrice))),
                    DataCell(Text(_currencyFormat.format(transaction.totalAmount))),
                    DataCell(Text(transaction.notes ?? '')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Color(0xFF1565C0),
                        onPressed: () => _showEditDialog(transaction),
                ),
              ),
            ],
                );
              }).toList(),
            ),
                ),
              ),
            ],
    );
  }

  Future<void> _showEditDialog(dynamic transaction) async {
    final TextEditingController weightController = TextEditingController(
      text: transaction.weight.toString(),
    );
    final TextEditingController unitPriceController = TextEditingController(
      text: transaction.unitPrice.toString(),
    );
    final TextEditingController notesController = TextEditingController(
      text: transaction.notes ?? '',
    );

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                transaction is Purchase ? Icons.shopping_cart : Icons.sell,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Text(
                transaction is Purchase ? 'Chỉnh sửa đơn mua' : 'Chỉnh sửa đơn bán',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại hàng: ${transaction.squidType.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Số lượng (kg)',
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Số lượng không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Đơn giá (₫/kg)',
                    controller: unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập đơn giá';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Đơn giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Ghi chú',
                    controller: notesController,
                    maxLines: 3,
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        actions: [
          TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setState(() => isLoading = true);
                        try {
                          final weight = double.parse(weightController.text);
                          final unitPrice = double.parse(unitPriceController.text);
                          final totalAmount = weight * unitPrice;

                          final dataProvider = Provider.of<DataProvider>(
                            context,
                            listen: false,
                          );

                          if (transaction is Purchase) {
                            await dataProvider.updatePurchase(
                              transaction.id,
                              weight: weight,
                              unitPrice: unitPrice,
                              totalAmount: totalAmount,
                              notes: notesController.text,
                            );
                          } else if (transaction is Sale) {
                            await dataProvider.updateSale(
                              transaction.id,
                              weight: weight,
                              unitPrice: unitPrice,
                              totalAmount: totalAmount,
                              notes: notesController.text,
                            );
                          }

                          if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                                content: Text('Cập nhật thành công'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: ${e.toString()}'),
                                backgroundColor: Colors.red,
      ),
    );
  }
                        } finally {
                          if (mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1565C0),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
