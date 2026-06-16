import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDriversScreen extends StatelessWidget {
  const ManageDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No drivers'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text(
                    '${data['email']}\nRole: ${data['role']}\nVehicle: ${data['vehicleId'] ?? 'Not assigned'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDriverDetails(context, docs[i].id, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDriverDetails(
    BuildContext context,
    String driverId,
    Map<String, dynamic> data,
  ) async {
    // Fetch all vehicles
    final vehiclesSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .get();
    final List<Map<String, dynamic>> vehicles = vehiclesSnapshot.docs.map((
      doc,
    ) {
      return {
        'id': doc.id,
        'plateNumber': doc.data()['plateNumber'] ?? 'No plate',
        'model': doc.data()['model'] ?? 'Unknown model',
        'driverId': doc.data()['driverId'],
      };
    }).toList();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Vehicle to ${data['name'] ?? 'Driver'}'),
        content: vehicles.isEmpty
            ? const Text('No vehicles available. Please add a vehicle first.')
            : DropdownButtonFormField<String>(
                hint: const Text('Select Vehicle'),
                items: vehicles.map<DropdownMenuItem<String>>((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle['id'] as String,
                    child: Text(
                      '${vehicle['plateNumber']} (${vehicle['model']})',
                    ),
                  );
                }).toList(),
                onChanged: (selectedVehicleId) async {
                  if (selectedVehicleId != null) {
                    // Update driver document
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(driverId)
                        .update({'vehicleId': selectedVehicleId});
                    // Update vehicle document
                    await FirebaseFirestore.instance
                        .collection('vehicles')
                        .doc(selectedVehicleId)
                        .update({'driverId': driverId});
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle assigned successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}
