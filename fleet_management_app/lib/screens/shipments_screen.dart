import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthService>(context).user?.id;
    final isManager = Provider.of<AuthService>(context).userRole == 'manager';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: isManager
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateShipmentDialog(context),
                  tooltip: 'Create Shipment',
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: isManager
            ? FirebaseFirestore.instance
                  .collection('shipments')
                  .orderBy('createdAt', descending: true)
                  .snapshots()
            : FirebaseFirestore.instance
                  .collection('shipments')
                  .where('driverId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No shipments found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['trackingNumber'] ?? 'No tracking',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text(data['status'] ?? 'pending'),
                            backgroundColor: _getStatusColor(data['status']),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(data['origin'] ?? 'Unknown origin'),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['destination'] ?? 'Unknown destination',
                            ),
                          ),
                        ],
                      ),
                      if (data['driverId'] != null && isManager) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Driver: ${data['driverId']?.substring(0, 8)}...',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (isManager)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _updateShipmentStatus(
                                context,
                                docs[i].id,
                                data['status'] ?? 'pending',
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Update Status'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteShipment(
                                context,
                                docs[i].id,
                                data['trackingNumber'],
                              ),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      if (!isManager && data['status'] != 'delivered')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('shipments')
                                  .doc(docs[i].id)
                                  .update({'status': 'delivered'});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marked as delivered'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Mark Delivered'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'in_transit':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showCreateShipmentDialog(BuildContext context) async {
    final TextEditingController trackingController = TextEditingController();
    final TextEditingController originController = TextEditingController();
    final TextEditingController destinationController = TextEditingController();
    String selectedStatus = 'pending';
    String? selectedDriverId;

    final driversSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    final Map<String, String> driverMap = {};
    for (var doc in driversSnapshot.docs) {
      driverMap[doc.id] = doc.data()['name'] ?? 'Unknown Driver';
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Create New Shipment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(labelText: 'Tracking Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Origin'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_transit',
                    child: Text('In Transit'),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child: Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (val) => selectedStatus = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                hint: const Text('Select Driver'),
                decoration: const InputDecoration(labelText: 'Assign Driver'),
                items: driverMap.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (val) => selectedDriverId = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (trackingController.text.isEmpty ||
                  originController.text.isEmpty ||
                  destinationController.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }
              await FirebaseFirestore.instance.collection('shipments').add({
                'trackingNumber': trackingController.text,
                'origin': originController.text,
                'destination': destinationController.text,
                'status': selectedStatus,
                'driverId': selectedDriverId,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Shipment created'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _updateShipmentStatus(
    BuildContext context,
    String shipmentId,
    String currentStatus,
  ) async {
    String newStatus = currentStatus;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: DropdownButtonFormField<String>(
          initialValue: newStatus,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'in_transit', child: Text('In Transit')),
            DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (val) => newStatus = val!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('shipments')
                  .doc(shipmentId)
                  .update({'status': newStatus});
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Status updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _deleteShipment(
    BuildContext context,
    String shipmentId,
    String trackingNumber,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shipment'),
        content: Text('Delete $trackingNumber? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('shipments')
        .doc(shipmentId)
        .delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
