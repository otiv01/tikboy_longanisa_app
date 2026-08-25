import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Your cart is empty!', style: TextStyle(fontSize: 16)));
          }

          final cartItems = cart.items.values.toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, i) {
                      final item = cartItems[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.fastfood, color: Colors.grey)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('₱${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => cart.removeSingleItem(item.id),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => cart.addItem(item.id, item.name, item.price),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                _buildSummaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('Delivery Fee', '₱${cart.deliveryFee.toStringAsFixed(2)}'),
                const Divider(),
                _buildSummaryRow('Total Amount', '₱${cart.totalAmount.toStringAsFixed(2)}', isTotal: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => _showReceiptDialog(context, cart),
                    child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  // System-generated automated receipt as outlined in the thesis requirements[cite: 1]
  void _showReceiptDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Successful! 🎉'),
        content: Text(
            'Your order has been placed successfully.\n\n'
                'Total Paid: ₱${cart.totalAmount.toStringAsFixed(2)}\n\n'
                'A digital receipt has been generated.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Back to Home', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}