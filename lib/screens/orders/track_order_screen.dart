import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final LatLng customerPos = const LatLng(14.1136, 121.5548);
  LatLng? riderPos;
  double distanceInKm = 0.0;
  String orderStatus = 'placed';
  bool hasRiderStarted = false;
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialOrderAndDelivery();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialOrderAndDelivery() async {
    try {
      final supabase = Supabase.instance.client;
      
      final orderRes = await supabase.from('orders').select('status').eq('id', widget.orderId).maybeSingle();
      if (orderRes != null) {
        setState(() {
          orderStatus = orderRes['status']?.toString() ?? 'placed';
        });
      }

      final deliveryRes = await supabase.from('deliveries').select().eq('order_id', widget.orderId).maybeSingle();
      if (deliveryRes != null) {
        setState(() {
          riderPos = LatLng(deliveryRes['lat'] as double, deliveryRes['lng'] as double);
          hasRiderStarted = true;
          _calculateDistance();
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial tracking data: $e');
    }
  }

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;

    _deliverySubscription = supabase
        .from('deliveries')
        .stream(primaryKey: ['order_id'])
        .eq('order_id', widget.orderId)
        .listen((data) {
          if (data.isNotEmpty) {
            final row = data.first;
            setState(() {
              riderPos = LatLng(row['lat'] as double, row['lng'] as double);
              hasRiderStarted = true;
              _calculateDistance();
            });
          }
        });

    _orderSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((data) {
          if (data.isNotEmpty) {
            final row = data.first;
            setState(() {
              orderStatus = row['status']?.toString() ?? orderStatus;
            });
          }
        });
  }

  void _calculateDistance() {
    if (riderPos == null) return;
    double distanceInMeters = Geolocator.distanceBetween(
      riderPos!.latitude,
      riderPos!.longitude,
      customerPos.latitude,
      customerPos.longitude,
    );
    setState(() {
      distanceInKm = distanceInMeters / 1000;
    });
  }

  Future<void> _callRider() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+639123456789');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone call'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int estimatedMinutes = (distanceInKm * 3).ceil();
    if (estimatedMinutes < 1) estimatedMinutes = 1;

    String displayId = widget.orderId;
    if (displayId.length > 8) {
      displayId = displayId.substring(0, 8).toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Track Order: ORD-$displayId', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: riderPos ?? customerPos,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tikboy_longanisa_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customerPos,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                        ),
                        if (riderPos != null)
                          Marker(
                            point: riderPos!,
                            width: 45,
                            height: 45,
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 30),
                                Icon(Icons.directions_bike, color: Colors.red, size: 25),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_bike, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderStatus == 'delivered'
                                    ? 'Order Delivered! 🎉'
                                    : hasRiderStarted
                                        ? 'Rider is on the way!'
                                        : 'Waiting for rider to start delivery',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderStatus == 'delivered'
                                    ? 'Enjoy your meal!'
                                    : hasRiderStarted
                                        ? '${distanceInKm.toStringAsFixed(2)} km • ~$estimatedMinutes mins'
                                        : 'Rider has not started sharing location yet',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Order ID: ORD-$displayId',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${orderStatus.toUpperCase()}',
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildTimelineItem(
                      'Order Placed',
                      'We have received your order.',
                      isCompleted: true,
                    ),
                    _buildTimelineItem(
                      'Order Confirmed',
                      'Tikboy is preparing your longganisa.',
                      isCompleted: orderStatus == 'confirmed' || orderStatus == 'out_for_delivery' || orderStatus == 'delivered',
                    ),
                    _buildTimelineItem(
                      'Out for Delivery',
                      'Your order is with our rider.',
                      isCompleted: orderStatus == 'out_for_delivery' || orderStatus == 'delivered',
                      isActive: orderStatus == 'out_for_delivery',
                    ),
                    _buildTimelineItem(
                      'Delivered',
                      'Enjoy your authentic Lucban flavors!',
                      isCompleted: orderStatus == 'delivered',
                      isLast: true,
                      isActive: orderStatus == 'delivered',
                    ),
                    const SizedBox(height: 30),
                    if (orderStatus == 'out_for_delivery')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _callRider,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Rider', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle,
      {bool isCompleted = false, bool isLast = false, bool isActive = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.red : Colors.grey[200],
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Colors.red.withValues(alpha: 0.2), width: 4) : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? Colors.red : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted ? Colors.black : Colors.grey[400],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.grey[600] : Colors.grey[300],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
