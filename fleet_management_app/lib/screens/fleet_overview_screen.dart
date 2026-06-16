import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FleetOverviewScreen extends StatelessWidget {
  const FleetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Overview'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .get(),
          FirebaseFirestore.instance.collection('vehicles').get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final drivers = snapshot.data![0].docs.length;
          final vehicles = snapshot.data![1].docs.length;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatCard(
                  'Total Drivers',
                  drivers.toString(),
                  Icons.people,
                ),
                _buildStatCard(
                  'Total Vehicles',
                  vehicles.toString(),
                  Icons.directions_car,
                ),
                _buildStatCard(
                  'Active Today',
                  '0',
                  Icons.timeline,
                ), // placeholder
                _buildStatCard(
                  'Avg. Fuel (L/100km)',
                  '12.5',
                  Icons.local_gas_station,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.indigo),
        title: Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(title),
      ),
    );
  }
}
