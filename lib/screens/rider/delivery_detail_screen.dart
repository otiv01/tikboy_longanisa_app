import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../services/location_service.dart';
import '../../widgets/success_dialog.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryDetailScreen({super.key, required this.order});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  late String _status;
  bool _isSharing = false;
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LatLng? riderPos = const LatLng(14.0250, 121.5950); // Near Wakas area
  LatLng customerPos = const LatLng(14.0200, 121.5910); // Barangay Wakas, Tayabas
  List<LatLng> routePoints = [];
  StreamSubscription? _positionStream;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status']?.toString() ?? 'confirmed';
    _isSharing = _locationService.isSharing;

    final destLat = (widget.order['destination_lat'] as num?)?.toDouble();
    final destLng = (widget.order['destination_lng'] as num?)?.toDouble();
    final addr = widget.order['address']?.toString() ?? '';

    if (addr.toLowerCase().contains('wakas')) {
      customerPos = const LatLng(14.0205, 121.5915);
    } else if (destLat != null && destLng != null) {
      customerPos = LatLng(destLat, destLng);
    } else {
      _geocodeAddress(addr);
    }

    _initRiderLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _geocodeAddress(String address) async {
    final lower = address.toLowerCase();
    if (lower.contains('wakas') || lower.contains('barangay wakas')) {
      if (mounted) {
        setState(() {
          customerPos = const LatLng(14.0205, 121.5915); // Exact Barangay Wakas Hall coordinates
        });
        try {
          _mapController.move(customerPos, 16.0);
        } catch (_) {}
      }
      return;
    } else if (lower.contains('lucban')) {
      if (mounted) {
        setState(() {
          customerPos = const LatLng(14.1136, 121.5548);
        });
        try {
          _mapController.move(customerPos, 16.0);
        } catch (_) {}
      }
      return;
    }

    try {
      final query = Uri.encodeComponent('$address, Quezon, Philippines');
      final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'tikboy_longanisa_app'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'].toString());
          final lon = double.parse(data[0]['lon'].toString());
          if (mounted) {
            setState(() {
              customerPos = LatLng(lat, lon);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding fallback: $e');
    }
  }

  Future<void> _initRiderLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          riderPos = LatLng(position.latitude, position.longitude);
        });
        _fetchOsrmRoute(riderPos!, customerPos);
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((pos) {
        if (mounted) {
          setState(() {
            riderPos = LatLng(pos.latitude, pos.longitude);
          });
          _fetchOsrmRoute(riderPos!, customerPos);
          try {
            _mapController.move(riderPos!, 15.0);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Error getting rider GPS: $e');
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

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final orderId = widget.order['id'].toString();

      await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);

      setState(() {
        _status = newStatus;
      });

      if (!mounted) return;
      SuccessDialog.show(
        context,
        title: 'Status Updated',
        message: 'Order status has been updated to $newStatus successfully! 🎉',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startDelivery() async {
    final localContext = context;
    final granted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Delivery & Share Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'We will share your live GPS location with the customer so they can track their fresh longganisa on the map!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Start Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );

    if (granted == true) {
      if (!mounted) return;
      final hasPermission = await _locationService.requestPermission(localContext);
      if (hasPermission) {
        final orderId = widget.order['id'].toString();
        final riderId = Supabase.instance.client.auth.currentUser?.id;

        if (riderId != null) {
          await _updateOrderStatus('out_for_delivery');
          _locationService.startSharing(orderId: orderId, riderId: riderId);
          setState(() {
            _isSharing = true;
          });
        }
      }
    }
  }

  Future<void> _markDelivered() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery & Payment'),
        content: const Text('Have you successfully delivered the order and collected the payment from the customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final orderId = widget.order['id'].toString();
      await _locationService.stopSharing(orderId: orderId);
      await _updateOrderStatus('delivered');
      setState(() {
        _isSharing = false;
      });
    }
  }

  Future<void> _callCustomer() async {
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
    final orderId = widget.order['id'].toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final address = widget.order['address']?.toString() ?? 'No address provided';
    final total = widget.order['total']?.toString() ?? '0';
    final items = widget.order['items'];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen background map using Positioned.fill
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: customerPos,
                initialZoom: 15.0,
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
          ),

          // 2. Floating Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Text(
                    'Order #ORD-$shortId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // 3. Draggable Bottom Sheet for details & actions
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Collection Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: Colors.red, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount to Collect (COD)', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('₱$total', style: const TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _callCustomer,
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Items Summary
                    const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (items is List)
                      ...items.map((item) {
                        final name = item['product_name'] ?? item['name'] ?? 'Item';
                        final qty = item['quantity'] ?? 1;
                        final price = item['price'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$qty x $name',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('₱${(price * qty)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 24),

                    // Primary Action Buttons
                    if (_status == 'confirmed' || _status == 'placed')
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _startDelivery,
                          icon: const Icon(Icons.navigation),
                          label: const Text(
                            'Start Delivery & Share GPS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                    if (_status == 'out_for_delivery') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _markDelivered,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Mark as Delivered & Collect Payment',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isSharing)
                        Center(
                          child: Text(
                            '🟢 Live GPS sharing active',
                            style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],

                    if (_status == 'delivered')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Completed Successfully!',
                              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
