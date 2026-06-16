class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? vehicleId;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.vehicleId,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role,
    'phone': phone,
    'vehicleId': vehicleId,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
    id: id,
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    role: map['role'] ?? 'driver',
    phone: map['phone'],
    vehicleId: map['vehicleId'],
    isActive: map['isActive'] ?? true,
    createdAt: DateTime.parse(
      map['createdAt'] ?? DateTime.now().toIso8601String(),
    ),
  );
}
