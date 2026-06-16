import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management_app/models/anomaly.dart';

void main() {
  test('Anomaly toMap and fromMap roundtrip', () {
    final original = Anomaly(
      id: 'a1',
      type: 'overspeeding',
      message: 'Exceeded',
      driverId: 'd1',
      speed: 120.5,
      latitude: 10.0,
      longitude: 20.0,
      timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
      isResolved: false,
    );

    final map = original.toMap();
    final reconstructed = Anomaly.fromMap('a1', map);

    expect(reconstructed.type, original.type);
    expect(reconstructed.message, original.message);
    expect(reconstructed.driverId, original.driverId);
    expect(reconstructed.speed, original.speed);
    expect(reconstructed.latitude, original.latitude);
    expect(reconstructed.longitude, original.longitude);
    expect(reconstructed.timestamp.toUtc(), original.timestamp.toUtc());
    expect(reconstructed.isResolved, original.isResolved);
  });
}
