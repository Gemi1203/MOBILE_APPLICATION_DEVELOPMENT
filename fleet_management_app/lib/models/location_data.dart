class LocationData {
  final String driverId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'lat': latitude,
    'lng': longitude,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    driverId: map['driverId'] ?? '',
    latitude: map['lat']?.toDouble() ?? 0.0,
    longitude: map['lng']?.toDouble() ?? 0.0,
    speed: map['speed']?.toDouble() ?? 0.0,
    heading: map['heading']?.toDouble() ?? 0.0,
    accuracy: map['accuracy']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(
      map['timestamp'] ?? DateTime.now().toIso8601String(),
    ),
  );
}
