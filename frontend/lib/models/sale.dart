import 'customer.dart';
import 'squid_type.dart';

class Sale {
  final int id;
  final int customerId;
  final int squidTypeId;
  final double weight;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer? customer;
  final SquidType? squidType;

  Sale({
    required this.id,
    required this.customerId,
    required this.squidTypeId,
    required this.weight,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.squidType,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      customerId: json['customer_id'],
      squidTypeId: json['squid_type_id'],
      weight: double.parse(json['weight'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      saleDate: DateTime.parse(json['sale_date']),
      paymentStatus: json['payment_status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      squidType: json['squid_type'] != null ? SquidType.fromJson(json['squid_type']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'squid_type_id': squidTypeId,
      'weight': weight,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'sale_date': saleDate.toIso8601String().split('T')[0],
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => paymentStatus == 'unpaid';
} 