import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('anomalies').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final Map<String, int> typeCount = {};
          for (var doc in docs) {
            final type = (doc.data() as Map)['type'] as String;
            typeCount[type] = (typeCount[type] ?? 0) + 1;
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Anomalies by Type',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: typeCount.entries.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (_, i) {
                      final entry = typeCount.entries.elementAt(i);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getColorForType(
                              entry.key,
                            ).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(entry.key),
                            color: _getColorForType(entry.key),
                          ),
                        ),
                        title: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF export will be available soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
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

  Color _getColorForType(String type) {
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
}
