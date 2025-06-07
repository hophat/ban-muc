import 'boat.dart';
import 'squid_type.dart';

class Purchase {
  final int id;
  final int boatId;
  final int squidTypeId;
  final double weight;
  final double unitPrice;
  final double totalAmount;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Boat? boat;
  final SquidType? squidType;

  Purchase({
    required this.id,
    required this.boatId,
    required this.squidTypeId,
    required this.weight,
    required this.unitPrice,
    required this.totalAmount,
    required this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.boat,
    this.squidType,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      boatId: json['boat_id'],
      squidTypeId: json['squid_type_id'],
      weight: double.parse(json['weight'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      purchaseDate: DateTime.parse(json['purchase_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      boat: json['boat'] != null ? Boat.fromJson(json['boat']) : null,
      squidType: json['squid_type'] != null ? SquidType.fromJson(json['squid_type']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boat_id': boatId,
      'squid_type_id': squidTypeId,
      'weight': weight,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 