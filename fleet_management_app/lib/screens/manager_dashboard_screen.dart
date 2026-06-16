import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'live_map_screen.dart';
import 'reports_screen.dart';
import 'shipments_screen.dart';
import 'manage_vehicles_screen.dart';
import 'manage_drivers_screen.dart';
import 'manage_geofences_screen.dart';
import '../widgets/anomaly_card.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppTheme.appName} · ${auth.user?.name ?? 'Manager'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Stats cards with real-time counts
          _buildStatsRow(),
          // Live anomaly feed
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Anomaly Feed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('anomalies')
                          .orderBy('timestamp', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No anomalies detected',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            bool resolved = false;
                            final val = data['isResolved'];
                            if (val is bool) {
                              resolved = val;
                            } else if (val is String) {
                              resolved = val.toLowerCase() == 'true';
                            }
                            return AnomalyCard(
                              id: docs[i].id,
                              type: data['type'] ?? '',
                              message: data['message'] ?? '',
                              driverId: data['driverId'] ?? '',
                              timestamp: data['timestamp'],
                              isResolved: resolved,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LiveMapScreen()),
        ),
        icon: const Icon(Icons.map),
        label: const Text('Live Map'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .snapshots(),
      builder: (context, driverSnapshot) {
        int driverCount = driverSnapshot.hasData
            ? driverSnapshot.data!.docs.length
            : 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('shipments')
              .snapshots(),
          builder: (context, shipmentSnapshot) {
            int shipmentCount = shipmentSnapshot.hasData
                ? shipmentSnapshot.data!.docs.length
                : 0;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('anomalies')
                  .snapshots(),
              builder: (context, anomalySnapshot) {
                int anomalyCount = anomalySnapshot.hasData
                    ? anomalySnapshot.data!.docs.length
                    : 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.indigoAccent],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Drivers',
                        driverCount.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Shipments',
                        shipmentCount.toString(),
                        Icons.local_shipping,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Alerts',
                        anomalyCount.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[900],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo, Colors.blue]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.directions_car, size: 36, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Fleet Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.white70),
              title: const Text(
                'Live Map',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveMapScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.white70),
              title: const Text(
                'Shipments',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white70),
              title: const Text(
                'Reports',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            const Divider(color: Colors.white24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ADMINISTRATION',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.white70),
              title: const Text(
                'Vehicles',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageVehiclesScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white70),
              title: const Text(
                'Drivers',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDriversScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fence, color: Colors.white70),
              title: const Text(
                'Geofences',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageGeofencesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
