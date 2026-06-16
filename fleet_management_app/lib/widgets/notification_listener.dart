import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// A widget that listens to real-time notifications and displays alerts
class DriverNotificationListener extends StatefulWidget {
  final Widget child;

  const DriverNotificationListener({super.key, required this.child});

  @override
  State<DriverNotificationListener> createState() =>
      _DriverNotificationListenerState();
}

class _DriverNotificationListenerState
    extends State<DriverNotificationListener> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();

    // Listen to notifications
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        _handleNotification(notification);
      }
    });
  }

  void _handleNotification(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Alert';
    final body = notification['body'] as String? ?? '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    // Show snackbar for important alerts
    if (data['priority'] == 'high' || data['type'] == 'anomaly') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body),
          duration: const Duration(seconds: 4),
          backgroundColor: _getColorForType(data['type']),
          action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
        ),
      );
    }

    // Handle specific notification types
    switch (data['type']) {
      case 'drowsiness_alert':
        _handleDrowsinessAlert(title, body, data);
        break;
      case 'overspeeding':
        _handleOverspeedingAlert(title, body, data);
        break;
      case 'geofence_exit':
        _handleGeofenceAlert(title, body, data);
        break;
      case 'harsh_braking':
        _handleHarshBrakingAlert(title, body, data);
        break;
      default:
        debugPrint('Notification received: $title - $body');
    }
  }

  void _handleDrowsinessAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(body)),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleOverspeedingAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.speed, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(body)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleGeofenceAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(body)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleHarshBrakingAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(body)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'drowsiness_alert':
        return Colors.purple;
      case 'overspeeding':
        return Colors.orange;
      case 'geofence_exit':
        return Colors.blue;
      case 'harsh_braking':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
