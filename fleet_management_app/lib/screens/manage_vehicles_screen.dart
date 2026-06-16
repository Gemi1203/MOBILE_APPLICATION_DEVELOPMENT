import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageVehiclesScreen extends StatefulWidget {
  const ManageVehiclesScreen({super.key});

  @override
  State<ManageVehiclesScreen> createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  String? _selectedDriverId;

  void _showAddVehicleDialog() async {
    // Fetch drivers for dropdown
    final driversSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    final Map<String, String> driverMap = {
      for (var doc in driversSnapshot.docs)
        doc.id: doc.data()['name'] ?? 'Unknown',
    };

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Plate Number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                hint: const Text('Assign Driver (optional)'),
                items: driverMap.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (val) => _selectedDriverId = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_plateController.text.isEmpty) return;
                await _firestore.collection('vehicles').add({
                  'plateNumber': _plateController.text,
                  'model': _modelController.text,
                  'driverId': _selectedDriverId,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                _plateController.clear();
                _modelController.clear();
                _selectedDriverId = null;
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('vehicles').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No vehicles'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['plateNumber']),
                  subtitle: Text(
                    'Model: ${data['model'] ?? 'N/A'}\nDriver: ${data['driverId']?.substring(0, 8) ?? 'Unassigned'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _firestore
                          .collection('vehicles')
                          .doc(docs[i].id)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
