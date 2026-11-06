import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../widgets/success_dialog.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final MapController _mapController = MapController();
  LatLng customerPos = const LatLng(14.0205, 121.5915); // Barangay Wakas Hall exact coords
  LatLng? riderPos;
  double distanceInKm = 0.0;
  String orderStatus = 'placed';
  String customerAddress = 'Loading delivery address...';
  bool hasRiderStarted = false;
  bool _hasShownFeedbackDialog = false;
  List<LatLng> routePoints = [];
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
      
      // 1. Fetch order status, address, and destination coordinates
      final orderRes = await supabase.from('orders').select('status, rating, address, destination_lat, destination_lng').eq('id', widget.orderId).maybeSingle();
      if (orderRes != null) {
        final addr = orderRes['address']?.toString() ?? 'Barangay Wakas Hall';
        final destLat = (orderRes['destination_lat'] as num?)?.toDouble();
        final destLng = (orderRes['destination_lng'] as num?)?.toDouble();

        setState(() {
          orderStatus = orderRes['status']?.toString() ?? 'placed';
          customerAddress = addr;
          if (addr.toLowerCase().contains('wakas')) {
            customerPos = const LatLng(14.0205, 121.5915); // Exact Barangay Wakas Hall
          } else if (destLat != null && destLng != null) {
            customerPos = LatLng(destLat, destLng);
          }
        });

        try {
          _mapController.move(customerPos, 16.0);
        } catch (_) {}

        if (orderStatus.toLowerCase() == 'delivered' && orderRes['rating'] == null) {
          _checkAndShowFeedback();
        }
      }

      // 2. Fetch delivery / rider position
      final deliveryRes = await supabase.from('deliveries').select().eq('order_id', widget.orderId).maybeSingle();
      if (deliveryRes != null) {
        final lat = (deliveryRes['lat'] as num?)?.toDouble() ?? (customerPos.latitude + 0.002);
        final lng = (deliveryRes['lng'] as num?)?.toDouble() ?? (customerPos.longitude + 0.002);
        setState(() {
          riderPos = LatLng(lat, lng);
          hasRiderStarted = true;
          _calculateDistance();
        });
        _fetchOsrmRoute(riderPos!, customerPos);
      } else if (orderStatus.toLowerCase() == 'out_for_delivery' || orderStatus.toLowerCase() == 'confirmed') {
        setState(() {
          riderPos = LatLng(customerPos.latitude + 0.003, customerPos.longitude + 0.003);
          hasRiderStarted = true;
          _calculateDistance();
        });
        _fetchOsrmRoute(riderPos!, customerPos);
      }
    } catch (e) {
      debugPrint('Error fetching initial tracking data: $e');
    }
  }

  Future<void> _fetchOsrmRoute(LatLng start, LatLng end) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final coords = routes[0]['geometry']['coordinates'] as List;
          if (mounted) {
            setState(() {
              routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fallback: $e');
      if (mounted) {
        setState(() {
          routePoints = [start, end];
        });
      }
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
            final lat = (row['lat'] as num?)?.toDouble() ?? customerPos.latitude;
            final lng = (row['lng'] as num?)?.toDouble() ?? customerPos.longitude;
            setState(() {
              riderPos = LatLng(lat, lng);
              hasRiderStarted = true;
              _calculateDistance();
            });
            _fetchOsrmRoute(riderPos!, customerPos);
          }
        });

    _orderSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((data) async {
          if (data.isNotEmpty) {
            final row = data.first;
            final newStatus = row['status']?.toString() ?? orderStatus;
            final addr = row['address']?.toString() ?? customerAddress;
            final destLat = (row['destination_lat'] as num?)?.toDouble();
            final destLng = (row['destination_lng'] as num?)?.toDouble();

            setState(() {
              orderStatus = newStatus;
              customerAddress = addr;
              if (addr.toLowerCase().contains('wakas')) {
                customerPos = const LatLng(14.0205, 121.5915);
              } else if (destLat != null && destLng != null) {
                customerPos = LatLng(destLat, destLng);
              }
              try {
                _mapController.move(customerPos, 16.0);
              } catch (_) {}
            });

            if ((newStatus.toLowerCase() == 'out_for_delivery' || newStatus.toLowerCase() == 'confirmed') && riderPos == null) {
              setState(() {
                riderPos = LatLng(customerPos.latitude + 0.003, customerPos.longitude + 0.003);
                hasRiderStarted = true;
                _calculateDistance();
              });
              _fetchOsrmRoute(riderPos!, customerPos);
            }

            if (newStatus.toLowerCase() == 'delivered' && row['rating'] == null) {
              _checkAndShowFeedback();
            }
          }
        });
  }

  void _checkAndShowFeedback() {
    if (_hasShownFeedbackDialog) return;
    _hasShownFeedbackDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showFeedbackDialog();
    });
  }

  void _showFeedbackDialog() {
    int rating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate Your Delivery 🌟', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your delivery experience with Tikboy Longanisa?', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: InputDecoration(
                  labelText: 'Write a review (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await Supabase.instance.client.from('orders').update({
                    'rating': 0,
                  }).eq('id', widget.orderId);
                } catch (e) {
                  debugPrint('Error updating skipped rating: $e');
                }
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await Supabase.instance.client.from('orders').update({
                    'rating': rating,
                    'review': reviewController.text.trim(),
                  }).eq('id', widget.orderId);

                  if (!mounted) return;
                  SuccessDialog.show(
                    context,
                    title: 'Thank You!',
                    message: 'Your feedback and rating have been submitted successfully! ⭐',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  );
                } catch (e) {
                  debugPrint('Error saving feedback: $e');
                }
              },
              child: const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: customerPos,
                    initialZoom: 16.0,
                    onMapReady: () {
                      try {
                        _mapController.move(customerPos, 16.0);
                      } catch (_) {}
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tikboy_longanisa_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (riderPos != null)
                          Polyline(
                            points: routePoints.isNotEmpty ? routePoints : [riderPos!, customerPos],
                            strokeWidth: 5.0,
                            color: Colors.red.shade600,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customerPos,
                          width: 45,
                          height: 45,
                          child: const Column(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue, size: 36),
                            ],
                          ),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '📍 Destination: $customerAddress',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        Flexible(
                          child: Text(
                            'Status: ${orderStatus.toUpperCase()}',
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
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
                      isCompleted: orderStatus.toLowerCase() == 'confirmed' || orderStatus.toLowerCase() == 'out_for_delivery' || orderStatus.toLowerCase() == 'delivered',
                    ),
                    _buildTimelineItem(
                      'Out for Delivery',
                      'Your order is with our rider.',
                      isCompleted: orderStatus.toLowerCase() == 'out_for_delivery' || orderStatus.toLowerCase() == 'delivered',
                      isActive: orderStatus.toLowerCase() == 'out_for_delivery',
                    ),
                    _buildTimelineItem(
                      'Delivered',
                      'Enjoy your authentic Lucban flavors!',
                      isCompleted: orderStatus.toLowerCase() == 'delivered',
                      isLast: true,
                      isActive: orderStatus.toLowerCase() == 'delivered',
                    ),
                    const SizedBox(height: 30),
                    if (orderStatus.toLowerCase() == 'out_for_delivery')
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
                    if (orderStatus.toLowerCase() == 'delivered')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showFeedbackDialog,
                          icon: const Icon(Icons.star, color: Colors.amber),
                          label: const Text('Leave / Update Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[50],
                            foregroundColor: Colors.amber[800],
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
