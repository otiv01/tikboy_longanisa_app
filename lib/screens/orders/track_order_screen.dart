import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackOrderScreen extends StatelessWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Starting coordinates for Lucban, Quezon
    const LatLng lucbanPos = LatLng(14.1136, 121.5548);
    const LatLng riderPos = LatLng(14.1150, 121.5560);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Track Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  options: const MapOptions(
                    initialCenter: lucbanPos,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tikboy_longanisa_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // User Location Marker
                        const Marker(
                          point: lucbanPos,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: Colors.blue, size: 40),
                        ),
                        // Rider Location Marker
                        const Marker(
                          point: riderPos,
                          width: 45,
                          height: 45,
                          child: Stack(
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
                // Floating Order Status Info
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
                          color: Colors.black.withOpacity(0.05),
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
                              Text(
                                'Estimated delivery: 10-15 mins',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                        Text(
                          orderId,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
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
                      'Expected 11:10 AM',
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
                border: isActive ? Border.all(color: Colors.red.withOpacity(0.2), width: 4) : null,
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
            onPressed: () {},
            icon: const Icon(Icons.phone),
            label: const Text('Call Rider', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.chat_outlined, color: Colors.black87),
        ),
      ],
    );
  }
}
