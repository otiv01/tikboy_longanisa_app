import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActiveOrderCard(context),
          const Divider(height: 32, thickness: 1),
          const Text('Order History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildHistoryOrderCard('Delivered', Colors.green),
          _buildHistoryOrderCard('Cancelled', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #ORD-2026-001', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('On the Way', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('2x Longganisa Classic, 1x Longganisa Sweet'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                icon: const Icon(Icons.location_on),
                label: const Text('Track Order'),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard(String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order #ORD-2025-099', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Total Amount: ₱350.00'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text('View Details')),
                ElevatedButton(onPressed: () {}, child: const Text('Reorder')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}