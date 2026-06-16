import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/anomaly.dart';

class AnomalyDetector {
  static double _lastSpeedKmh = 0;
  static DateTime _lastMovementTime = DateTime.now();
  static const double speedLimit = 80.0;
  static const int idleThresholdMs = 10 * 60 * 1000;
  static const double harshBrakingThreshold = 20.0;
  static DateTime? _lastBrakingCheck;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Drowsiness detection
  static Timer? _drowsinessTimer;
  static const int drowsinessTimeoutSeconds = 30 * 60; // 30 minutes

  static void startDrowsinessTimer(String driverId) {
    _drowsinessTimer?.cancel();
    _drowsinessTimer = Timer(Duration(seconds: drowsinessTimeoutSeconds), () {
      _reportAnomaly(
        type: 'drowsiness',
        message:
            'Potential driver drowsiness detected (no activity for 30 minutes)',
        driverId: driverId,
      );
    });
  }

  static void resetDrowsinessTimer(String driverId) {
    if (_drowsinessTimer == null) return;
    _drowsinessTimer?.cancel();
    _drowsinessTimer = Timer(Duration(seconds: drowsinessTimeoutSeconds), () {
      _reportAnomaly(
        type: 'drowsiness',
        message:
            'Potential driver drowsiness detected (no activity for 30 minutes)',
        driverId: driverId,
      );
    });
  }

  static void driverInteracted(String driverId) {
    resetDrowsinessTimer(driverId);
  }

  static void checkSpeed(double speedKmh) {
    if (speedKmh > speedLimit) {
      _reportAnomaly(
        type: 'overspeeding',
        message:
            'Overspeeding: ${speedKmh.toStringAsFixed(1)} km/h (limit $speedLimit)',
        speed: speedKmh,
      );
    }
    _lastSpeedKmh = speedKmh;
  }

  static void checkIdleTime(int currentTimestamp) {
    final now = DateTime.now();
    if (_lastSpeedKmh < 1.0 &&
        now.difference(_lastMovementTime).inMilliseconds > idleThresholdMs) {
      _reportAnomaly(type: 'idle_time', message: 'Vehicle idle > 10 minutes');
    } else if (_lastSpeedKmh >= 1.0) {
      _lastMovementTime = now;
    }
  }

  static void checkHarshBraking(double currentSpeedMs) {
    final now = DateTime.now();
    if (_lastBrakingCheck == null) {
      _lastBrakingCheck = now;
      return;
    }
    final speedDrop = (_lastSpeedKmh - (currentSpeedMs * 3.6)).abs();
    final timeDiff = now.difference(_lastBrakingCheck!).inSeconds;
    if (timeDiff <= 2 && speedDrop > harshBrakingThreshold) {
      _reportAnomaly(
        type: 'harsh_braking',
        message:
            'Harsh braking: speed dropped ${speedDrop.toStringAsFixed(1)} km/h in $timeDiff sec',
        speed: currentSpeedMs * 3.6,
      );
    }
    _lastBrakingCheck = now;
  }

  static Future<void> _reportAnomaly({
    required String type,
    required String message,
    double? speed,
    String? driverId,
  }) async {
    final user = driverId ?? FirebaseAuth.instance.currentUser?.uid;
    if (user == null) return;
    final anomaly = Anomaly(
      id: '',
      type: type,
      message: message,
      driverId: user,
      speed: speed,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('anomalies').add(anomaly.toMap());
  }
}
