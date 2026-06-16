import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageGeofencesScreen extends StatefulWidget {
  const ManageGeofencesScreen({super.key});

  @override
  State<ManageGeofencesScreen> createState() => _ManageGeofencesScreenState();
}

class _ManageGeofencesScreenState extends State<ManageGeofencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  Future<void> _showAddGeofenceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Geofence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Zone Name'),
            ),
            TextField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _radiusController,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
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
              if (_nameController.text.isEmpty ||
                  _latController.text.isEmpty ||
                  _lngController.text.isEmpty) {
                // Instead of `return;`, use `return;` inside async function is ok, but to avoid lint, we do:
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }
              await _firestore.collection('geofences').add({
                'name': _nameController.text,
                'latitude': double.parse(_latController.text),
                'longitude': double.parse(_lngController.text),
                'radius': double.parse(
                  _radiusController.text.isEmpty
                      ? '100'
                      : _radiusController.text,
                ),
                'createdAt': FieldValue.serverTimestamp(),
              });
              _nameController.clear();
              _latController.clear();
              _lngController.clear();
              _radiusController.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Geofences'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGeofenceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('geofences').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No geofences'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Text(
                    'Lat: ${data['latitude']}, Lng: ${data['longitude']}, Radius: ${data['radius']}m',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _firestore
                          .collection('geofences')
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
