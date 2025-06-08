import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/expense_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/phone_input_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/sale_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/report_screen.dart';
import 'screens/farm_setup_screen.dart';
import 'screens/squid_types_management.dart';
import 'screens/setting_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => DataProvider(),
        ),
        ChangeNotifierProxyProvider<ApiService, PurchaseProvider>(
          create: (context) => PurchaseProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) => PurchaseProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, SaleProvider>(
          create: (context) => SaleProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) => SaleProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, ExpenseProvider>(
          create: (context) => ExpenseProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) => ExpenseProvider(apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý vựa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1565C0), // Navy blue
        scaffoldBackgroundColor: Color(0xFFF5F5F5), // Light gray
        
        // Typography tối ưu cho U50
        textTheme: TextTheme(
          // Heading lớn - 24px
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
          // Heading trung bình - 20px  
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
          // Title - 18px
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
          // Body text lớn - 16px
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF424242),
          ),
          // Body text trung bình - 14px
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF757575),
          ),
        ),
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        // Card theme
        cardTheme: CardTheme(
          elevation: 2,
          margin: EdgeInsets.all(8),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFBDBDBD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFBDBDBD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(fontSize: 14),
        ),
        
        // Color scheme đơn giản
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1565C0),
          brightness: Brightness.light,
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF757575),
          surface: Colors.white,
          error: Color(0xFFD32F2F),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      locale: const Locale('vi', 'VN'),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return authProvider.isAuthenticated 
              ? DashboardScreen() 
              : LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/phone-input': (context) => PhoneInputScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/purchases': (context) => PurchaseScreen(),
        '/sales': (context) => SaleScreen(),
        '/expenses': (context) => ExpenseScreen(),
        '/reports': (context) => ReportScreen(),
        '/farm-setup': (context) => FarmSetupScreen(),
        '/setting': (context) => SettingScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          // Load master data when user is authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<DataProvider>(context, listen: false).loadMasterData();
          });
          return DashboardScreen();
        }

        return LoginScreen();
      },
    );
  }
}

// Placeholder screen for routes that haven't been implemented yet
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang phát triển',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tính năng "$title" sẽ sớm được hoàn thiện',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}
