import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/drowsiness_detector.dart';
import '../utils/pagination_helper.dart';
import '../theme/app_theme.dart';
import 'live_map_screen.dart';
import 'shipments_screen.dart';
import 'drowsiness_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isTracking = false;
  late LocationService _locationService;
  late DrowsinessService _drowsinessService;
  late PaginationHelper _paginationHelper;
  final List<QueryDocumentSnapshot> _alerts = [];
  bool _isLoadingMoreAlerts = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _drowsinessService = DrowsinessService();
    _paginationHelper = PaginationHelper(pageSize: 15);
    _loadInitialAlerts();
  }

  Future<void> _loadInitialAlerts() async {
    final userId = Provider.of<AuthService>(context, listen: false).user?.id;
    if (userId == null) return;

    final query = FirebaseFirestore.instance
        .collection('anomalies')
        .where('driverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    final docs = await _paginationHelper.loadNextPage(query);
    setState(() => _alerts.addAll(docs));
  }

  Future<void> _loadMoreAlerts() async {
    if (_isLoadingMoreAlerts || !_paginationHelper.hasMore) return;

    setState(() => _isLoadingMoreAlerts = true);

    final userId = Provider.of<AuthService>(context, listen: false).user?.id;
    if (userId != null) {
      final query = FirebaseFirestore.instance
          .collection('anomalies')
          .where('driverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      final docs = await _paginationHelper.loadNextPage(query);
      setState(() {
        _alerts.addAll(docs);
        _isLoadingMoreAlerts = false;
      });
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _locationService.dispose();
    _drowsinessService.stopDetection();
    _drowsinessService.dispose();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    final userId = Provider.of<AuthService>(context, listen: false).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }
    try {
      if (_isTracking) {
        _locationService.stopTracking();
        _drowsinessService.stopDetection();
        setState(() => _isTracking = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tracking stopped')));
        }
      } else {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
        _locationService.startTracking(userId);
        _drowsinessService.startDetection();
        setState(() => _isTracking = true);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tracking started')));
        }
      }
    } catch (e) {
      debugPrint('Error toggling tracking: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Called when the user interacts with the screen (any tap)
  void _onUserInteraction() {
    final userId = Provider.of<AuthService>(context, listen: false).user?.id;
    if (userId != null && _isTracking) {
      _drowsinessService.resetActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return GestureDetector(
      onTap: _onUserInteraction,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${AppTheme.appName} · Driver',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _isTracking ? Icons.gps_fixed : Icons.gps_off,
                color: _isTracking ? Colors.lightGreen : Colors.white70,
              ),
              onPressed: _toggleTracking,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Driver info card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppTheme.primary),
                ),
                title: Text(
                  user?.name ?? 'Driver',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Chip(
                  label: Text(_isTracking ? 'GPS ON' : 'GPS OFF'),
                  backgroundColor: _isTracking ? Colors.green : Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Action buttons row (now 3 buttons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Shipments button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShipmentsScreen(), // removed const
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Shipments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Live Map button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveMapScreen(), // removed const
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Live Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Drowsiness Detection button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrowsinessScreen(), // ✅ no const
                          ),
                        );
                      },
                      icon: const Icon(Icons.bed),
                      label: const Text('Drowsiness'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Alerts section (scrollable)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _alerts.isEmpty
                            ? const Center(
                                child: Text(
                                  'No alerts found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    _alerts.length +
                                    (_isLoadingMoreAlerts ? 1 : 0) +
                                    (_paginationHelper.hasMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  // Show loading indicator
                                  if (i == _alerts.length) {
                                    return _paginationHelper.hasMore
                                        ? const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          )
                                        : const SizedBox.shrink();
                                  }

                                  // Trigger load more
                                  if (!_isLoadingMoreAlerts &&
                                      _paginationHelper.hasMore &&
                                      i >= _alerts.length - 5) {
                                    _loadMoreAlerts();
                                  }

                                  final data =
                                      _alerts[i].data() as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getColorForType(
                                            data['type'],
                                          ).withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForType(data['type']),
                                          color: _getColorForType(data['type']),
                                        ),
                                      ),
                                      title: Text(
                                        data['type'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(data['message'] ?? ''),
                                      trailing: Text(
                                        _formatTimestamp(data['timestamp']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'overspeeding':
        return Icons.speed;
      case 'harsh_braking':
        return Icons.car_crash;
      case 'idle_time':
        return Icons.timer;
      case 'drowsiness':
        return Icons.bed;
      default:
        return Icons.warning;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'overspeeding':
        return Colors.orange;
      case 'harsh_braking':
        return Colors.red;
      case 'idle_time':
        return Colors.blue;
      case 'drowsiness':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime t = timestamp is String
          ? DateTime.parse(timestamp)
          : (timestamp as Timestamp).toDate();
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
