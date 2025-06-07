import 'farm.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Farm? farm;
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.farm,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      farm: json['farm'] != null ? Farm.fromJson(json['farm']) : null,
      phone: json['phone'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'farm': farm?.toJson(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
} 