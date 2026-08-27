import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

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
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionTitle('Active Orders', hasDot: true),
          _buildActiveOrderCard(),
          const SizedBox(height: 25),
          _buildSectionTitle('Order History'),
          _buildHistoryOrderCard(
            orderId: 'ORD-2026-002',
            date: 'Mar 28, 2026 • 10:15 AM',
            status: 'Delivered',
            statusColor: Colors.teal,
            statusIcon: Icons.check_circle_outline,
            items: [
              {'name': 'Tikboy Classic Breakfast Bundle', 'price': 260},
            ],
            total: 300,
          ),
          _buildHistoryOrderCard(
            orderId: 'ORD-2026-003',
            date: 'Mar 25, 2026 • 4:00 PM',
            status: 'Delivered',
            statusColor: Colors.teal,
            statusIcon: Icons.check_circle_outline,
            items: [
              {'name': 'Tikboy Longganisa Sweet', 'qty': 3, 'price': 255},
              {'name': 'Tikboy Longganisa Spicy', 'qty': 1, 'price': 85},
            ],
            total: 380,
          ),
          _buildHistoryOrderCard(
            orderId: 'ORD-2026-004',
            date: 'Mar 20, 2026 • 8:00 AM',
            status: 'Cancelled',
            statusColor: Colors.grey,
            statusIcon: Icons.cancel_outlined,
            items: [
              {'name': 'Tikboy Embutido Regular', 'qty': 2, 'price': 240},
            ],
            total: 280,
          ),
        ],
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

  Widget _buildActiveOrderCard() {
    return Card(
      elevation: 0,
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORD-2026-001', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Mar 31, 2026 • 2:30 PM', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions_bike, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('On the Way', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildOrderItem('Tikboy Longganisa Classic', 160, qty: 2),
            _buildOrderItem('Tikboy Embutido Special', 150, qty: 1),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Text('₱310', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions_bike, size: 18),
                label: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard({
    required String orderId,
    required String date,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required List<Map<String, dynamic>> items,
    required double total,
  }) {
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
                    Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...items.map((item) => _buildOrderItem(item['name'], item['price'], qty: item['qty'] ?? 1)),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('₱${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reorder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
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