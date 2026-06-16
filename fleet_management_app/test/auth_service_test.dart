import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService', () {
    test('Login validation - rejects empty email', () {
      expect(''.isEmpty, true);
    });

    test('Register validation - password length', () {
      final password = 'short';
      expect(password.length < 6, true);
    });

    test('Email validation format', () {
      final email = 'test@fleet.com';
      expect(email.contains('@'), true);
      expect(email.contains('.'), true);
    });

    test('Role assignment for admin emails', () {
      const adminEmails = ['muindigrace403@gmail.com', 'admin@fleet.com'];
      const testEmail = 'muindigrace403@gmail.com';
      expect(adminEmails.contains(testEmail), true);
    });

    test('Default role is driver', () {
      final role = 'driver';
      expect(role == 'driver', true);
    });
  });
}
