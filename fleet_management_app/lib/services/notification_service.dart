import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  bool _initialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!_notificationController.isClosed && !_disposed) {
      _notificationController.add({
        'title': message.notification?.title ?? 'Alert',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    if (!_notificationController.isClosed && !_disposed) {
      _notificationController.add({
        'title': message.notification?.title ?? 'Alert',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'opened': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_notificationController.isClosed) {
      _notificationController.close();
    }
  }

  bool get isInitialized => _initialized;
  bool get isDisposed => _disposed;
}
