import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, int> anomalyCounts = {};
  int totalAnomalies = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('anomalies')
        .get();
    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final type = doc.data()['type'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    setState(() {
      anomalyCounts = counts;
      totalAnomalies = counts.values.fold(0, (acc, c) => acc + c);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : anomalyCounts.isEmpty
          ? const Center(child: Text('No anomaly data available'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anomaly Summary',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total anomalies: $totalAnomalies',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Breakdown by type:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: anomalyCounts.entries.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (_, i) {
                        final entry = anomalyCounts.entries.elementAt(i);
                        final percentage = (entry.value / totalAnomalies * 100)
                            .toStringAsFixed(1);
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getColorForType(entry.key),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: entry.value / totalAnomalies,
                                        backgroundColor: Colors.grey[300],
                                        color: _getColorForType(entry.key),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$percentage% (${entry.value} events)',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'overspeeding':
        return Colors.orange;
      case 'harsh_braking':
        return Colors.red;
      case 'idle_time':
        return Colors.blue;
      case 'drowsiness':
        return Colors.purple;
      case 'geofence_alert':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
