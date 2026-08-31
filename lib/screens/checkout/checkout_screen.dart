import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Delivery Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Full Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption('Cash on Delivery', Icons.money),
          _buildPaymentOption('GCash / E-Wallet', Icons.account_balance_wallet),
          const Divider(height: 32),
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Total Amount',
            '₱${cart.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _showReceiptDialog(context, cart),
            child: const Text(
              'Confirm & Place Order',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return RadioListTile<String>(
      title: Text(title),
      secondary: Icon(icon, color: Colors.red),
      value: title,
      groupValue: _selectedPayment,
      onChanged: (value) => setState(() => _selectedPayment = value!),
      activeColor: Colors.red,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 14,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Colors.red : Colors.black,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }

  void _showReceiptDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order Successful! 🎉'),
        content: Text(
          'Your order has been placed.\n\n'
          'Total Paid: ₱${cart.totalAmount.toStringAsFixed(2)}\n'
          'Payment: $_selectedPayment\n\n'
          'A digital receipt has been generated.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.of(dialogContext).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
