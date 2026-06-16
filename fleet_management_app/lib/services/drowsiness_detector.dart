import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple inactivity-based drowsiness service.
///
/// This is intentionally lightweight: it monitors activity resets and
/// sends a drowsiness anomaly to Firestore when the inactivity threshold
/// is exceeded. It exposes start/stop/reset controls and a status stream
/// for UI binding.
class DrowsinessService {
  static final DrowsinessService _instance = DrowsinessService._internal();
  factory DrowsinessService() => _instance;
  DrowsinessService._internal();

  bool _isDetecting = false;
  DateTime? _lastActivity;
  bool _timerRunning = false;
  Timer? _timer;
  bool _disposed = false;

  final Duration _pollInterval = const Duration(seconds: 10);
  final Duration _inactivityThreshold = const Duration(minutes: 5);

  late final StreamController<bool> _statusController =
      StreamController.broadcast();

  Stream<bool> get statusStream => _statusController.stream;
  bool get isDetecting => _isDetecting;
  bool get isDisposed => _disposed;

  void startDetection() {
    if (_disposed) {
      throw StateError('DrowsinessService has been disposed');
    }
    if (_isDetecting) return;
    _isDetecting = true;
    _lastActivity = DateTime.now();
    if (!_statusController.isClosed) {
      _statusController.add(true);
    }
    _runTimer();
  }

  void stopDetection() {
    if (_disposed) return;
    _isDetecting = false;
    _timer?.cancel();
    _timer = null;
    _timerRunning = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
  }

  void resetActivity() {
    if (!_isDetecting || _disposed) return;
    _lastActivity = DateTime.now();
    // keep UI informed
    if (!_statusController.isClosed) {
      _statusController.add(true);
    }
  }

  void _runTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _timer = Timer.periodic(_pollInterval, (t) async {
      if (!_isDetecting || _disposed) {
        t.cancel();
        _timerRunning = false;
        return;
      }
      if (_lastActivity == null) return;
      final inactiveDuration = DateTime.now().difference(_lastActivity!);
      if (inactiveDuration >= _inactivityThreshold) {
        try {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null && !_disposed) {
            await FirebaseFirestore.instance.collection('anomalies').add({
              'type': 'drowsiness',
              'message':
                  'Driver drowsiness detected (inactivity for ${_inactivityThreshold.inMinutes} minutes)',
              'driverId': userId,
              'timestamp': DateTime.now().toIso8601String(),
              'isResolved': false,
            });
          }
          // reset activity to avoid repeated alerts
          _lastActivity = DateTime.now();
          // notify listeners (UI may choose to show alert)
          if (!_statusController.isClosed && !_disposed) {
            _statusController.add(true);
          }
        } catch (e) {
          debugPrint('Error reporting drowsiness: $e');
        }
      }
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _timerRunning = false;
    _isDetecting = false;
    if (!_statusController.isClosed) {
      _statusController.close();
    }
  }
}
