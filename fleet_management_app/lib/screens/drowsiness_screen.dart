import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/drowsiness_detector.dart';

class DrowsinessScreen extends StatefulWidget {
  const DrowsinessScreen({super.key});

  @override
  State<DrowsinessScreen> createState() => _DrowsinessScreenState();
}

class _DrowsinessScreenState extends State<DrowsinessScreen> {
  final DrowsinessService _service = DrowsinessService();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _isDetecting = _service.isDetecting;
    _service.statusStream.listen((status) {
      if (mounted) setState(() => _isDetecting = status);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drowsiness Detection'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isDetecting ? 'Monitoring for drowsiness' : 'Detection stopped',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isDetecting ? null : () => _service.startDetection(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Start'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isDetecting ? () => _service.stopDetection() : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isDetecting ? () => _service.resetActivity() : null,
                  child: const Text('Reset Activity'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Drowsiness Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('anomalies')
                    .where('type', isEqualTo: 'drowsiness')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('No drowsiness alerts'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['message'] ?? 'Drowsiness alert'),
                        subtitle: Text(data['driverId'] ?? ''),
                        trailing: Text(data['timestamp']?.toString() ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
