import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_data.dart';
import 'anomaly_detector.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<geolocator.Position>? _positionStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'driver_locations',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isTracking = false;
  String? _currentDriverId;
  final Map<String, bool> _insideGeofence = {}; // geofenceId -> inside status
  bool _disposed = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking(String driverId) async {
    if (_isTracking) return;
    _currentDriverId = driverId;
    _isTracking = true;

    // Initialize background execution for Android foreground service.
    try {
      final androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'Fleet Manager',
        notificationText: 'Tracking location in background',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: const AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );
      await FlutterBackground.initialize(androidConfig: androidConfig);
      await FlutterBackground.enableBackgroundExecution();
    } catch (_) {
      // ignore — background may not be available on all platforms
    }

    await _initPermissionsAndStart(driverId);
  }

  Future<void> _initPermissionsAndStart(String driverId) async {
    final geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();
    geolocator.LocationPermission currentPermission = permission;
    if (currentPermission == geolocator.LocationPermission.denied) {
      currentPermission = await geolocator.Geolocator.requestPermission();
    }
    if (currentPermission == geolocator.LocationPermission.deniedForever ||
        currentPermission == geolocator.LocationPermission.denied) {
      // Cannot proceed without permission
      _isTracking = false;
      return;
    }

    final geolocator.LocationSettings locationSettings =
        geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          distanceFilter: 10,
        );

    try {
      _positionStream =
          geolocator.Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (geolocator.Position pos) async {
              if (!_isTracking || _disposed) return;
              _sendLocationToFirebase(driverId, pos);
              AnomalyDetector.checkSpeed(pos.speed * 3.6);
              AnomalyDetector.checkIdleTime(
                DateTime.now().millisecondsSinceEpoch,
              );
              AnomalyDetector.checkHarshBraking(pos.speed);
              await _checkGeofences(pos); // ← geofence monitoring
            },
            onError: (err) async {
              debugPrint('LocationService error: $err');
              _isTracking = false;
              await _bufferError({
                'error': err.toString(),
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
            cancelOnError: true,
          );
      // subscribe to connectivity and attempt buffered sync when back online
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        if (!_disposed && results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
          _syncBufferedLocations();
        }
      });
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
      await _bufferError({
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void stopTracking() {
    if (_disposed) return;
    try {
      _positionStream?.cancel();
      _connectivitySub?.cancel();
      _isTracking = false;
      if (_currentDriverId != null) {
        _dbRef.child(_currentDriverId!).remove().catchError((e) {
          debugPrint('Error removing driver location: $e');
        });
      }
    } catch (e) {
      debugPrint('Error in stopTracking: $e');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopTracking();
    _insideGeofence.clear();
    _currentDriverId = null;
  }

  void _sendLocationToFirebase(String driverId, geolocator.Position pos) {
    if (_disposed) return;
    final locationData = LocationData(
      driverId: driverId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      speed: pos.speed,
      heading: pos.heading,
      accuracy: pos.accuracy,
      timestamp: DateTime.now(),
    );
    final map = locationData.toMap();
    try {
      _dbRef.child(driverId).set(map).catchError((e) {
        debugPrint('Error writing to Firebase Realtime DB: $e');
        _bufferLocation(map);
      });
      // attempt to sync any buffered locations
      _syncBufferedLocations();
    } catch (e) {
      debugPrint('Error in _sendLocationToFirebase: $e');
      // buffer locally when network/db write fails
      _bufferLocation(map);
    }
  }

  Future<void> _bufferLocation(Map<String, dynamic> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> buffered =
          prefs.getStringList('unsynced_locations') ?? [];
      final entry = {
        'payload': map,
        'retry': 0,
        'ts': DateTime.now().toIso8601String(),
      };
      buffered.add(jsonEncode(entry));
      await prefs.setStringList('unsynced_locations', buffered);
      debugPrint('Buffered location: ${buffered.length} items in queue');
    } catch (e) {
      debugPrint('Error buffering location: $e');
    }
  }

  Future<void> _bufferError(Map<String, dynamic> e) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> buffered =
          prefs.getStringList('location_errors') ?? [];
      buffered.add(jsonEncode(e));
      await prefs.setStringList('location_errors', buffered);
    } catch (ex) {
      debugPrint('Error buffering error log: $ex');
    }
  }

  Future<void> _syncBufferedLocations() async {
    if (_disposed) return;
    const int maxRetries = 5;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> buffered =
          prefs.getStringList('unsynced_locations') ?? [];
      if (buffered.isEmpty) return;
      final List<String> updated = List<String>.from(buffered);
      debugPrint('Syncing ${buffered.length} buffered locations...');

      for (final s in buffered) {
        if (_disposed) break;
        try {
          final Map<String, dynamic> entry =
              jsonDecode(s) as Map<String, dynamic>;
          final Map<String, dynamic> payload = Map<String, dynamic>.from(
            entry['payload'] ?? {},
          );
          // attempt to write payload
          await _firestore.collection('locations_buffered').add(payload);
          updated.remove(s);
        } catch (e) {
          try {
            final Map<String, dynamic> entry =
                jsonDecode(s) as Map<String, dynamic>;
            int retry = (entry['retry'] ?? 0) as int;
            retry++;
            if (retry > maxRetries) {
              debugPrint(
                'Max retries exceeded for location entry, moving to errors',
              );
              // move to errors
              final prefs2 = await SharedPreferences.getInstance();
              final List<String> errors =
                  prefs2.getStringList('location_errors') ?? [];
              errors.add(
                jsonEncode({
                  'error': e.toString(),
                  'payload': entry['payload'],
                  'ts': DateTime.now().toIso8601String(),
                }),
              );
              await prefs2.setStringList('location_errors', errors);
              updated.remove(s);
            } else {
              entry['retry'] = retry;
              final idx = updated.indexOf(s);
              if (idx >= 0) updated[idx] = jsonEncode(entry);
            }
          } catch (ex) {
            debugPrint('Error processing malformed buffer entry: $ex');
          }
        }
      }
      await prefs.setStringList('unsynced_locations', updated);
    } catch (e) {
      debugPrint('Error syncing buffered locations: $e');
    }
  }

  Future<void> _checkGeofences(geolocator.Position pos) async {
    if (_disposed || _currentDriverId == null) return;
    try {
      final snapshot = await _firestore.collection('geofences').get();
      for (var doc in snapshot.docs) {
        if (_disposed) break;
        try {
          final data = doc.data();
          final lat = data['latitude']?.toDouble() ?? 0;
          final lng = data['longitude']?.toDouble() ?? 0;
          final radius = data['radius']?.toDouble() ?? 100;
          final distance = geolocator.Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            lat,
            lng,
          );
          final isInside = distance <= radius;
          final wasInside = _insideGeofence[doc.id] ?? false;

          if (isInside != wasInside) {
            _insideGeofence[doc.id] = isInside;
            try {
              // Log event to Firestore and optionally notify manager
              await _firestore.collection('geofence_events').add({
                'geofenceId': doc.id,
                'geofenceName': data['name'] ?? 'Unknown',
                'driverId': _currentDriverId,
                'event': isInside ? 'ENTER' : 'EXIT',
                'latitude': pos.latitude,
                'longitude': pos.longitude,
                'timestamp': FieldValue.serverTimestamp(),
              });
              // Create an anomaly for the manager feed
              await _firestore.collection('anomalies').add({
                'type': 'geofence_alert',
                'message': isInside
                    ? 'Vehicle entered ${data['name']}'
                    : 'Vehicle exited ${data['name']}',
                'driverId': _currentDriverId,
                'timestamp': DateTime.now().toIso8601String(),
                'isResolved': false,
              });
            } catch (e) {
              debugPrint('Error logging geofence event: $e');
            }
          }
        } catch (e) {
          debugPrint('Error checking geofence ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _checkGeofences: $e');
    }
  }
}
