import 'package:intl/intl.dart';

class Formatters {
  // Currency formatter for Vietnamese Dong
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // Date formatters
  static final DateFormat date = DateFormat('dd/MM/yyyy');
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat time = DateFormat('HH:mm');
  static final DateFormat monthYear = DateFormat('MM/yyyy');

  // Format currency amount
  static String formatCurrency(double amount) {
    return currency.format(amount);
  }

  // Format date
  static String formatDate(DateTime date) {
    return Formatters.date.format(date);
  }

  // Format date time
  static String formatDateTime(DateTime dateTime) {
    return Formatters.dateTime.format(dateTime);
  }

  // Format time
  static String formatTime(DateTime time) {
    return Formatters.time.format(time);
  }

  // Format month year
  static String formatMonthYear(DateTime date) {
    return monthYear.format(date);
  }

  // Parse date from string (dd/MM/yyyy)
  static DateTime? parseDate(String dateString) {
    try {
      return date.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Convert date to API format (yyyy-MM-dd)
  static String toApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Parse API date format (yyyy-MM-dd)
  static DateTime? parseApiDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Format weight with kg unit
  static String formatWeight(double weight) {
    return '${weight.toStringAsFixed(1)} kg';
  }

  // Format number with thousand separators
  static String formatNumber(double number) {
    return NumberFormat('#,##0.##', 'vi_VN').format(number);
  }

  // Get payment status display text
  static String getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'partial':
        return 'Thanh toán một phần';
      default:
        return 'Không xác định';
    }
  }

  // Get user role display text
  static String getUserRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'staff':
        return 'Nhân viên';
      default:
        return 'Không xác định';
    }
  }
} 