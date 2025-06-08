import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../utils/formatters.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'expense_screen.dart';
import 'report_screen.dart';
import 'login_screen.dart';
import 'setting_screen.dart';
import 'profile_sreen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    DashboardHomeScreen(),
    PurchaseScreen(),
    SaleScreen(),
    ExpenseScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1565C0),
          unselectedItemColor: Color(0xFF757575),
          selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          iconSize: 28,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Mua hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sell),
              label: 'Bán hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Chi phí',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Báo cáo',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHomeScreen extends StatefulWidget {
  @override
  _DashboardHomeScreenState createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Quản Lý Trại hàng'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingScreen()),
            ),
            tooltip: 'Cài đặt',
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 28),
            onPressed: () => {
              authProvider.logout(),
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
            },
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dataProvider.loadAllData(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng, ${authProvider.user?.name ?? ''}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hôm nay: ${Formatters.formatDate(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // KPI Cards
              Text(
                'Tổng quan hệ thống',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              
              Consumer<DataProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  double totalPurchases = provider.purchases.fold(0, (sum, p) => sum + p.totalAmount);
                  double totalSales = provider.sales.fold(0, (sum, s) => sum + s.totalAmount);
                  double totalExpenses = provider.expenses.fold(0, (sum, e) => sum + e.amount);
                  double profit = totalSales - totalPurchases - totalExpenses;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Tổng mua',
                              Formatters.formatCurrency(totalPurchases),
                              Icons.shopping_cart,
                              Color(0xFF1565C0),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              'Tổng bán',
                              Formatters.formatCurrency(totalSales),
                              Icons.sell,
                              Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Chi phí',
                              Formatters.formatCurrency(totalExpenses),
                              Icons.account_balance_wallet,
                              Color(0xFFFF8F00),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              'Lợi nhuận',
                              Formatters.formatCurrency(profit),
                              Icons.trending_up,
                              profit >= 0 ? Color(0xFF2E7D32) : Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Chức năng chính',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Mua hàng mới',
                      'Ghi nhận đợt mua hàng',
                      Icons.add_shopping_cart,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseScreen())),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Bán hàng',
                      'Ghi nhận bán hàng',
                      Icons.point_of_sale,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleScreen())),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Ghi chi phí',
                      'Quản lý chi phí',
                      Icons.receipt_long,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseScreen())),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Xem báo cáo',
                      'Thống kê tài chính',
                      Icons.analytics,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen())),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Recent Activity
              Text(
                'Hoạt động gần đây',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              
              Consumer<DataProvider>(
                builder: (context, provider, child) {
                  var recentPurchases = provider.purchases.take(3).toList();
                  var recentSales = provider.sales.take(3).toList();
                  
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recentPurchases.isNotEmpty) ...[
                          Text(
                            'Mua hàng gần đây:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          ...recentPurchases.map((purchase) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${Formatters.formatDate(purchase.purchaseDate)} - ${purchase.squidType?.name ?? ''}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(purchase.totalAmount),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          SizedBox(height: 16),
                        ],
                        
                        if (recentSales.isNotEmpty) ...[
                          Text(
                            'Bán hàng gần đây:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          ...recentSales.map((sale) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${Formatters.formatDate(sale.saleDate)} - ${sale.customer?.name ?? ''}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(sale.totalAmount),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                        
                        if (recentPurchases.isEmpty && recentSales.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Chưa có hoạt động nào',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF1565C0), size: 32),
            SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Color(0xFF1565C0),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 