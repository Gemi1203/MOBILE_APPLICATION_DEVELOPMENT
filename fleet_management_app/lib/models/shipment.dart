class Shipment {
  final String id;
  final String trackingNumber;
  final String origin;
  final String destination;
  final String? driverId;
  final String? vehicleId;
  final String status;
  final List<dynamic> waypoints;
  final DateTime createdAt;
  final DateTime? pickedAt;
  final DateTime? deliveredAt;

  Shipment({
    required this.id,
    required this.trackingNumber,
    required this.origin,
    required this.destination,
    this.driverId,
    this.vehicleId,
    this.status = 'pending',
    this.waypoints = const [],
    required this.createdAt,
    this.pickedAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
    'trackingNumber': trackingNumber,
    'origin': origin,
    'destination': destination,
    'driverId': driverId,
    'vehicleId': vehicleId,
    'status': status,
    'waypoints': waypoints,
    'createdAt': createdAt.toIso8601String(),
    'pickedAt': pickedAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  factory Shipment.fromMap(String id, Map<String, dynamic> map) => Shipment(
    id: id,
    trackingNumber: map['trackingNumber'] ?? '',
    origin: map['origin'] ?? '',
    destination: map['destination'] ?? '',
    driverId: map['driverId'],
    vehicleId: map['vehicleId'],
    status: map['status'] ?? 'pending',
    waypoints: map['waypoints'] ?? [],
    createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    pickedAt: map['pickedAt'] != null ? DateTime.parse(map['pickedAt']) : null,
    deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
  );
}