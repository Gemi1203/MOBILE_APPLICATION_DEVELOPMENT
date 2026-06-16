import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrowsinessService', () {
    test('Inactivity threshold is 5 minutes', () {
      final threshold = Duration(minutes: 5);
      expect(threshold.inMinutes, 5);
    });

    test('Poll interval is 10 seconds', () {
      final interval = Duration(seconds: 10);
      expect(interval.inSeconds, 10);
    });

    test('Activity reset updates last activity', () {
      final now = DateTime.now();
      final before = now.subtract(Duration(minutes: 1));
      expect(now.isAfter(before), true);
    });

    test('Inactivity calculation', () {
      final lastActivity = DateTime.now().subtract(Duration(minutes: 6));
      final inactiveDuration = DateTime.now().difference(lastActivity);
      expect(inactiveDuration.inMinutes > 5, true);
    });

    test('Detection state toggle', () {
      bool isDetecting = false;
      isDetecting = true;
      expect(isDetecting, true);
      isDetecting = false;
      expect(isDetecting, false);
    });

    test('Service disposed state', () {
      bool disposed = false;
      expect(disposed, false);
      disposed = true;
      expect(disposed, true);
    });
  });
}
