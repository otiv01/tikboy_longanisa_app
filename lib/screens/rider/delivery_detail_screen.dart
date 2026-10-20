import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

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

  @override
  void initState() {
    super.initState();
    _status = widget.order['status']?.toString() ?? 'confirmed';
    _isSharing = _locationService.isSharing;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $newStatus! 🎉'), backgroundColor: Colors.green),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Order #ORD-$shortId', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),

            // Delivery Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 6)],
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
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
            const SizedBox(height: 20),

            // Order Items Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
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
                            Text('$qty x $name', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            Text('₱${(price * qty)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 30),

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
                  label: const Text('Start Delivery & Share GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  label: const Text('Mark as Delivered & Collect Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          ],
        ),
      ),
    );
  }
}
