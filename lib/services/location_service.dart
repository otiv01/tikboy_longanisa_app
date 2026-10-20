import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Timer? _throttleTimer;
  Position? _lastPosition;
  bool _isSharing = false;

  bool get isSharing => _isSharing;

  Future<bool> requestPermission(BuildContext? context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null) {
        _showErrorDialog(context, 'Location services are disabled. Please enable GPS.');
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context != null) {
          _showErrorDialog(context, 'Location permissions are denied.');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null) {
        _showErrorDialog(context, 'Location permissions are permanently denied. Please enable them in app settings.');
      }
      return false;
    }

    return true;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void startSharing({required String orderId, required String riderId}) {
    if (_isSharing) return;
    _isSharing = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _lastPosition = position;
    });

    // Throttle upserts to deliveries table every 4 seconds
    _throttleTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_lastPosition != null && _isSharing) {
        try {
          final supabase = Supabase.instance.client;
          await supabase.from('deliveries').upsert({
            'order_id': orderId,
            'rider_id': riderId,
            'lat': _lastPosition!.latitude,
            'lng': _lastPosition!.longitude,
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('📍 Rider location synced: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
        } catch (e) {
          debugPrint('❌ Error syncing rider location: $e');
        }
      }
    });
  }

  Future<void> stopSharing({String? orderId}) async {
    _isSharing = false;
    _positionStream?.cancel();
    _throttleTimer?.cancel();
    _positionStream = null;
    _throttleTimer = null;

    if (orderId != null) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('deliveries').delete().eq('order_id', orderId);
        debugPrint('🛑 Stopped location sharing and cleared delivery row for order $orderId');
      } catch (e) {
        debugPrint('❌ Error clearing delivery row: $e');
      }
    }
  }
}
