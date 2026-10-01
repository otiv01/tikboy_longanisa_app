import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/directus_api_service.dart';
import '../../models/product_model.dart';
import '../notifications/notification_screen.dart';
import '../../widgets/product_options_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final apiService = DirectusApiService();
  String _selectedCategory = 'All';

  void _showProductOptions(BuildContext context, Product product, String baseUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductOptionsBottomSheet(
        product: product,
        baseUrl: baseUrl,
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.fastfood, color: Colors.red, size: 40);
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: apiService.fetchProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No products available'));
            }

            final rawProducts = snapshot.data ?? [];
            
            // Consolidated 4 master products as requested
            final List<Product> allProducts = [
              Product(
                id: 'longanisa_pork',
                name: 'Longanisa (Pork)',
                price: 85.0,
                category: 'Longanisa',
                imageUrl: 'assets/img_1.jpg',
                description: 'Regular, Spicy & Sweet varieties available',
                isBestseller: true,
              ),
              Product(
                id: 'longanisa_chicken',
                name: 'Longanisa Chicken',
                price: 75.0,
                category: 'Chicken',
                imageUrl: 'assets/img_1.jpg',
                description: 'Small & Big sizes available',
                isBestseller: true,
              ),
              Product(
                id: 'embutido',
                name: 'Embutido',
                price: 50.0,
                category: 'Embutido',
                imageUrl: 'assets/embutido.png',
                description: 'Small & Big sizes available',
                isBestseller: false,
              ),
              Product(
                id: 'chili_oil',
                name: 'Crispy Chili Garlic Oil',
                price: 150.0,
                category: 'Condiments',
                imageUrl: 'assets/chiliOIL.jpg',
                description: 'Extra crispy and spicy',
                isBestseller: false,
              ),
            ];

            final bestsellers = allProducts.where((p) => p.isBestseller).toList();
            
            // Apply filtering logic
            final filteredProducts = _selectedCategory == 'All' 
                ? allProducts 
                : allProducts.where((p) => p.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildSearchBar(),
                  _buildPromoBanner(),
                  if (bestsellers.isNotEmpty && _selectedCategory == 'All') ...[
                    _buildSectionHeader('Bestsellers', onSeeAll: () {}),
                    _buildBestsellers(context, bestsellers, apiService.baseUrl),
                  ],
                  _buildSectionHeader(_selectedCategory == 'All' ? 'Our Products' : '$_selectedCategory Products'),
                  _buildCategories(),
                  if (filteredProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text('No products found in this category')),
                    )
                  else
                    _buildProductGrid(context, filteredProducts, apiService.baseUrl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.red[50],
            child: const Icon(Icons.person, color: Colors.red, size: 28),
          ),
          Row(
            children: [
              _buildIconButton(Icons.shopping_cart_outlined, () {}),
              const SizedBox(width: 10),
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    children: [
                      _buildIconButton(
                        Icons.notifications_none_rounded,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        ),
                      ),
                      if (provider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${provider.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🔥 LIMITED OFFER',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Taste the Authentic\nFlavor!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Free delivery on orders above ₱300',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            ),
            child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (title.contains('Bestsellers')) const Text('🔥 ', style: TextStyle(fontSize: 18)),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildBestsellers(BuildContext context, List<Product> bestsellers, String baseUrl) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: bestsellers.length,
        itemBuilder: (context, index) => _buildBestsellerCard(context, bestsellers[index], baseUrl),
      ),
    );
  }

  Widget _buildBestsellerCard(BuildContext context, Product product, String baseUrl) {
    final String imageUrl = product.getFullImageUrl(baseUrl);

    return GestureDetector(
      onTap: () => _showProductOptions(context, product, baseUrl),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      color: Colors.grey[200],
                      height: 100,
                      width: double.infinity,
                      child: _buildProductImage(imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favs, child) {
                        final isFav = favs.isFavorite(product.id.toString());
                        return GestureDetector(
                          onTap: () => favs.toggleFavorite(product.id.toString()),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(product.description!, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1),
                    const SizedBox(height: 4),
                    Text('₱${product.price.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () => _showProductOptions(context, product, baseUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('+ Add', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['All', 'Longganisa', 'Chicken', 'Embutido', 'Condiments'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final category = categories[i];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products, String baseUrl) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildGridCard(context, products[index], baseUrl),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, Product product, String baseUrl) {
    final String imageUrl = product.getFullImageUrl(baseUrl);

    return GestureDetector(
      onTap: () => _showProductOptions(context, product, baseUrl),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    color: Colors.grey[200],
                    height: 110,
                    width: double.infinity,
                    child: _buildProductImage(imageUrl),
                  ),
                ),
                if (product.isBestseller)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('BESTSELLER', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favs, child) {
                      final isFav = favs.isFavorite(product.id.toString());
                      return GestureDetector(
                        onTap: () => favs.toggleFavorite(product.id.toString()),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                        maxLines: 1,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₱${product.price.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                        GestureDetector(
                          onTap: () => _showProductOptions(context, product, baseUrl),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.red, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
