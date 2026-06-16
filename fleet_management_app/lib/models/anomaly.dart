class Anomaly {
  final String id;
  final String type;
  final String message;
  final String driverId;
  final double? speed;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  bool isResolved;

  Anomaly({
    required this.id,
    required this.type,
    required this.message,
    required this.driverId,
    this.speed,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'message': message,
    'driverId': driverId,
    'speed': speed,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'isResolved': isResolved,
  };

  factory Anomaly.fromMap(String id, Map<String, dynamic> map) => Anomaly(
    id: id,
    type: map['type'] ?? '',
    message: map['message'] ?? '',
    driverId: map['driverId'] ?? '',
    speed: map['speed']?.toDouble(),
    latitude: map['latitude']?.toDouble(),
    longitude: map['longitude']?.toDouble(),
    timestamp: DateTime.parse(
      map['timestamp'] ?? DateTime.now().toIso8601String(),
    ),
    isResolved: map['isResolved'] ?? false,
  );
}
