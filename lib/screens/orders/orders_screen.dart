import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/directus_api_service.dart';
import '../../providers/auth_provider.dart';
import 'track_order_screen.dart';
import '../../widgets/success_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _ordersFuture = DirectusApiService().fetchOrders(auth.accessToken);
  }

  void _showRefundDialog(OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for your refund request:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Wrong items, damaged product...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await DirectusApiService().updateOrderStatus(order.id!, 'Refund Requested', auth.accessToken);
                if (!mounted) return;
                SuccessDialog.show(
                  context,
                  title: 'Refund Requested',
                  message: 'Your refund request has been submitted successfully.',
                );
                setState(() => _refreshOrders());
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to request refund: $e')),
                );
              }
            },
            child: const Text('Submit Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => setState(() => _refreshOrders()),
          ),
        ],
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          final orders = snapshot.data!;
          final activeOrders = orders.where((o) => o.status.toLowerCase() != 'cancelled' && (o.status.toLowerCase() != 'delivered' || o.rating == null)).toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('No Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    const Text('Your ongoing orders will appear here.\nCheck Order History in your Profile for past orders.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshOrders()),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionTitle('Active Orders', hasDot: true),
                ...activeOrders.map((o) => _buildActiveOrderCard(o)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          if (hasDot) ...[
            const Icon(Icons.circle, size: 8, color: Colors.red),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    String displayId = order.id ?? '';
    if (displayId.length > 8) {
      displayId = displayId.substring(0, 8).toUpperCase();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORD-$displayId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('MMM dd, yyyy • h:mm a').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bike, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(order.status, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...order.items.map((item) => _buildOrderItem(item.name, item.price, qty: item.quantity)),
            if (order.address != null && order.address!.isNotEmpty) ...[
              const Divider(height: 30),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address!,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('₱${order.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrackOrderScreen(orderId: order.id ?? ''),
                          ),
                        );
                        setState(() => _refreshOrders());
                      },
                      icon: const Icon(Icons.directions_bike, size: 18),
                      label: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                if (order.status.toLowerCase() != 'refund requested' && order.status.toLowerCase() != 'refunded') ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () => _showRefundDialog(order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Refund', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String name, num price, {int qty = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('x$qty ', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text('₱${price.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }
}
