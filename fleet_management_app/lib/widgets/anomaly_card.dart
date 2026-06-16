import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnomalyCard extends StatelessWidget {
  final String id;
  final String type;
  final String message;
  final String driverId;
  final dynamic timestamp;
  final dynamic isResolved; // can be bool, String, or null

  const AnomalyCard({
    super.key,
    required this.id,
    required this.type,
    required this.message,
    required this.driverId,
    this.timestamp,
    this.isResolved = false,
  });

  bool _getResolved() {
    if (isResolved is bool) return isResolved;
    if (isResolved is String) return isResolved.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _getResolved();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(), color: _getColor()),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                type.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (!resolved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              'Driver: ${driverId.substring(0, 8)}... • ${_formatTimestamp()}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            resolved ? Icons.check_circle : Icons.circle_outlined,
            color: resolved ? Colors.green : Colors.grey,
          ),
          onPressed: resolved
              ? null
              : () async {
                  await FirebaseFirestore.instance
                      .collection('anomalies')
                      .doc(id)
                      .update({'isResolved': true});
                },
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'overspeeding':
        return Icons.speed;
      case 'harsh_braking':
        return Icons.car_crash;
      case 'idle_time':
        return Icons.timer;
      case 'route_deviation':
        return Icons.route;
      default:
        return Icons.warning;
    }
  }

  Color _getColor() {
    if (_getResolved()) return Colors.grey;
    switch (type) {
      case 'overspeeding':
        return Colors.orange;
      case 'harsh_braking':
        return Colors.red;
      case 'idle_time':
        return Colors.blue;
      case 'route_deviation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp() {
    if (timestamp == null) return '';
    try {
      DateTime t;
      if (timestamp is String) {
        t = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        t = timestamp.toDate();
      } else {
        return '';
      }
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes} min ago';
      if (diff.inDays < 1) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }
}
