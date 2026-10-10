import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  // Customer delivery destination (Lucban, Quezon center as sample)
  final LatLng customerPos = const LatLng(14.1136, 121.5548);
  // Rider current location (simulated or live device location)
  LatLng riderPos = const LatLng(14.1160, 121.5580);
  double distanceInKm = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  void _calculateDistance() {
    double distanceInMeters = Geolocator.distanceBetween(
      riderPos.latitude,
      riderPos.longitude,
      customerPos.latitude,
      customerPos.longitude,
    );
    setState(() {
      distanceInKm = distanceInMeters / 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Estimate arrival time: ~3 minutes per kilometer in town traffic
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
          // Real Map using OpenStreetMap
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: customerPos,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tikboy_longanisa_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Customer Location Marker
                        Marker(
                          point: customerPos,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                        ),
                        // Rider Location Marker
                        Marker(
                          point: riderPos,
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
                // Floating Order Status Info with live distance & ETA
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
                              const Text(
                                'Rider is on the way!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${distanceInKm.toStringAsFixed(2)} km • ~$estimatedMinutes mins',
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
          // Status Timeline
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
                        const Text(
                          'View Order Details',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildTimelineItem(
                      'Order Placed',
                      'We have received your order.',
                      '10:30 AM',
                      isCompleted: true,
                    ),
                    _buildTimelineItem(
                      'Order Confirmed',
                      'Tikboy is preparing your longganisa.',
                      '10:35 AM',
                      isCompleted: true,
                    ),
                    _buildTimelineItem(
                      'Out for Delivery',
                      'Your order is with our rider.',
                      '10:50 AM',
                      isCompleted: true,
                      isActive: true,
                    ),
                    _buildTimelineItem(
                      'Delivered',
                      'Enjoy your authentic Lucban flavors!',
                      'Expected in $estimatedMinutes mins',
                      isLast: true,
                    ),
                    const SizedBox(height: 30),
                    _buildContactRiderButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String time,
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
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted ? Colors.red[300] : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRiderButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling delivery rider...')),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call Rider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
