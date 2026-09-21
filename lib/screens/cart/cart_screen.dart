import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/directus_api_service.dart';
import '../../models/order_model.dart';
import '../profile/saved_addresses_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final apiService = DirectusApiService();

    // Find the default address
    final defaultAddress = addressProvider.addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : AddressItem(id: '', label: '', address: ''),
    );

    if (defaultAddress.address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first'), backgroundColor: Colors.orange),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()));
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final order = OrderModel(
        totalAmount: cart.totalAmount,
        date: DateTime.now(),
        address: defaultAddress.address,
        items: cart.items.values.map((item) {
          return OrderItem(
            productId: item.id,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
          );
        }).toList(),
      );

      await apiService.createOrder(order, auth.accessToken);

      if (mounted) {
        cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully! 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('SESSION_EXPIRED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please sign in again.'), backgroundColor: Colors.orange),
          );
          auth.logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final items = cart.items.values.toList();
    final itemKeys = cart.items.keys.toList();

    final defaultAddress = addressProvider.addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : AddressItem(id: '', label: 'No Address', address: 'Click to add a delivery address'),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Cart',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${cart.distinctItemsCount} items',
                style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _buildCartItem(context, cart, itemKeys[i], items[i]),
                  ),
                ),
                _buildAddressSection(context, defaultAddress),
                _buildPromoAndProgress(cart),
                _buildOrderSummary(cart),
              ],
            ),
    );
  }

  Widget _buildAddressSection(BuildContext context, AddressItem address) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                child: const Text('Change', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      address.address,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart, String id, CartItem item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey[100],
                child: const Icon(Icons.fastfood, color: Colors.red),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('per pack (6 pcs)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text('₱${item.price.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text('₱${(item.price * item.quantity).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => cart.removeItem(id),
                      child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQtyBtn(Icons.remove, () => cart.removeSingleItem(id)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      _buildQtyBtn(Icons.add, () => cart.addItem(id, item.name, item.price), isRed: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isRed = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isRed ? Colors.red : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: isRed ? Colors.white : Colors.grey),
      ),
    );
  }

  Widget _buildPromoAndProgress(CartProvider cart) {
    double progress = cart.subtotal / 300;
    if (progress > 1) progress = 1;
    double remaining = 300 - cart.subtotal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3E5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      remaining > 0 ? 'Add ₱${remaining.toInt()} more for FREE delivery!' : 'You unlocked FREE delivery!',
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSummaryRow('Subtotal (${cart.itemCount} items)', cart.subtotal),
          _buildSummaryRow('Delivery Fee', cart.deliveryFee),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '₱${cart.totalAmount.toInt()}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isOrdering || cart.items.isEmpty ? null : () => _placeOrder(context, cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isOrdering
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text('₱${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
