import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management_app/models/location_data.dart';

void main() {
  test('LocationData toMap and fromMap roundtrip', () {
    final original = LocationData(
      driverId: 'driver123',
      latitude: 1.23,
      longitude: 4.56,
      speed: 12.3,
      heading: 90.0,
      accuracy: 5.0,
      timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
    );

    final map = original.toMap();
    final reconstructed = LocationData.fromMap(map);

    expect(reconstructed.driverId, original.driverId);
    expect(reconstructed.latitude, original.latitude);
    expect(reconstructed.longitude, original.longitude);
    expect(reconstructed.speed, original.speed);
    expect(reconstructed.heading, original.heading);
    expect(reconstructed.accuracy, original.accuracy);
    expect(reconstructed.timestamp.toUtc(), original.timestamp.toUtc());
  });
}
