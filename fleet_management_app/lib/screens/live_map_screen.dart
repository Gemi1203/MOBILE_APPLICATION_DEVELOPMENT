import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final Set<Marker> _markers = {};
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'driver_locations',
  );
  final Map<String, String> _driverNames = {};

  @override
  void initState() {
    super.initState();
    _loadDriverNames();
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final Set<Marker> newMarkers = {};
      data.forEach((driverId, location) {
        final locMap = location as Map;
        final lat = (locMap['lat'] ?? 0.0).toDouble();
        final lng = (locMap['lng'] ?? 0.0).toDouble();
        final speed = locMap['speed'] ?? 0.0;
        final marker = Marker(
          markerId: MarkerId(driverId.toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: _driverNames[driverId] ?? 'Driver $driverId',
            snippet: 'Speed: ${(speed * 3.6).toStringAsFixed(1)} km/h',
          ),
          icon: speed > 20
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
        );
        newMarkers.add(marker);
      });
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
        });
      }
    });
  }

  Future<void> _loadDriverNames() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    for (var doc in snapshot.docs) {
      _driverNames[doc.id] = doc.data()['name'] ?? 'Driver';
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Fleet Map')),
      body: GoogleMap(
        onMapCreated: (controller) {},
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.7749, -122.4194),
          zoom: 12,
        ),
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}
