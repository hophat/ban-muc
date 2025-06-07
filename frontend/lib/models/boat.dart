class Boat {
  final int id;
  final String name;
  final String ownerName;
  final String? phone;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Boat({
    required this.id,
    required this.name,
    required this.ownerName,
    this.phone,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Boat.fromJson(Map<String, dynamic> json) {
    return Boat(
      id: json['id'],
      name: json['name'],
      ownerName: json['owner_name'],
      phone: json['phone'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 