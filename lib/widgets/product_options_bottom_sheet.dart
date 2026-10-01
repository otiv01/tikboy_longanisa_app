import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class ProductOptionsBottomSheet extends StatefulWidget {
  final Product product;
  final String baseUrl;

  const ProductOptionsBottomSheet({
    super.key,
    required this.product,
    required this.baseUrl,
  });

  @override
  State<ProductOptionsBottomSheet> createState() => _ProductOptionsBottomSheetState();
}

class _ProductOptionsBottomSheetState extends State<ProductOptionsBottomSheet> {
  String _selectedFlavor = 'Regular';
  String _selectedSize = 'Small';
  int _quantity = 1;

  bool get _isPorkLonganisa {
    final name = widget.product.name.toLowerCase();
    return name.contains('longanisa') && !name.contains('chicken');
  }

  bool get _isChickenLonganisa {
    final name = widget.product.name.toLowerCase();
    return name.contains('chicken');
  }

  bool get _isEmbutido {
    final name = widget.product.name.toLowerCase();
    return name.contains('embutido');
  }

  bool get _isChiliOil {
    final name = widget.product.name.toLowerCase();
    return name.contains('chili') || name.contains('oil');
  }

  double get _calculatedPrice {
    if (_isChickenLonganisa) {
      return _selectedSize == 'Big' ? 150.0 : 75.0;
    } else if (_isEmbutido) {
      return _selectedSize == 'Big' ? 100.0 : 50.0;
    } else if (_isChiliOil) {
      return 150.0;
    } else if (_isPorkLonganisa) {
      if (_selectedFlavor == 'Regular') {
        return _selectedSize == 'Big' ? 170.0 : 85.0;
      } else if (_selectedFlavor == 'Spicy') {
        return _selectedSize == 'Big' ? 180.0 : 90.0;
      } else if (_selectedFlavor == 'Sweet') {
        return 200.0; // Sweet per kilo
      }
    }
    return widget.product.price;
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.fastfood, color: Colors.red);
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.product.getFullImageUrl(widget.baseUrl);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 15),

            // Product Header Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: _buildProductImage(imageUrl),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.description ?? 'Authentic homemade style',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${_calculatedPrice.toInt()}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // 1. Flavor / Category Selection (Only for Pork Longanisa)
            if (_isPorkLonganisa) ...[
              const Text(
                'Choose Category / Flavor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ['Regular', 'Spicy', 'Sweet'].map((flavor) {
                  final isSelected = _selectedFlavor == flavor;
                  return ChoiceChip(
                    label: Text(flavor == 'Sweet' ? '$flavor (₱200/kilo)' : flavor),
                    selected: isSelected,
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    onSelected: (selected) {
                      setState(() {
                        _selectedFlavor = flavor;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // 2. Type / Size Selection (For Pork Longanisa, Chicken Longanisa, Embutido)
            if (!_isChiliOil && (_selectedFlavor != 'Sweet' || !_isPorkLonganisa)) ...[
              const Text(
                'Choose Type / Size',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ['Small', 'Big'].map((size) {
                  final isSelected = _selectedSize == size;
                  String priceLabel = size;
                  if (_isPorkLonganisa) {
                    if (_selectedFlavor == 'Regular') {
                      priceLabel = size == 'Small' ? 'Small (₱85)' : 'Big (₱170)';
                    } else if (_selectedFlavor == 'Spicy') {
                      priceLabel = size == 'Small' ? 'Small (₱90)' : 'Big (₱180)';
                    }
                  } else if (_isChickenLonganisa) {
                    priceLabel = size == 'Small' ? 'Small (₱75)' : 'Big (₱150)';
                  } else if (_isEmbutido) {
                    priceLabel = size == 'Small' ? 'Small (₱50)' : 'Big (₱100)';
                  }

                  return ChoiceChip(
                    label: Text(priceLabel),
                    selected: isSelected,
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    onSelected: (selected) {
                      setState(() {
                        _selectedSize = size;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _quantity > 1 ? Colors.red : Colors.grey,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.red,
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  final variantDesc = _isPorkLonganisa && _selectedFlavor == 'Sweet'
                      ? 'Sweet'
                      : (_isChiliOil ? 'Standard' : '$_selectedFlavor, $_selectedSize');
                      
                  final cartId = '${widget.product.id}_$variantDesc';
                  final customName = '${widget.product.name} [$variantDesc]';
                  
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    cartId,
                    customName,
                    _calculatedPrice,
                    quantity: _quantity,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $_quantity x $customName to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  'Add to Cart - ₱${(_calculatedPrice * _quantity).toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
