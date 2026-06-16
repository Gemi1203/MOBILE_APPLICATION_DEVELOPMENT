import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management_app/models/user.dart';

void main() {
  test('AppUser toMap and fromMap roundtrip', () {
    final original = AppUser(
      id: 'u1',
      email: 'test@example.com',
      name: 'Tester',
      role: 'driver',
      phone: '123',
      vehicleId: 'v1',
      isActive: true,
      createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
    );

    final map = original.toMap();
    final reconstructed = AppUser.fromMap('u1', map);

    expect(reconstructed.email, original.email);
    expect(reconstructed.name, original.name);
    expect(reconstructed.role, original.role);
    expect(reconstructed.phone, original.phone);
    expect(reconstructed.vehicleId, original.vehicleId);
    expect(reconstructed.isActive, original.isActive);
    expect(reconstructed.createdAt.toUtc(), original.createdAt.toUtc());
  });
}
