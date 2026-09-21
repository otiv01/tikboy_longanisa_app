class Product {
  final dynamic id; // Use dynamic to handle both Int and UUID strings
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isBestseller;
  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isBestseller = false,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Safely parse isBestseller
    bool bestseller = false;
    var rawBestseller = json['is_bestseller'];
    if (rawBestseller != null) {
      if (rawBestseller is bool) {
        bestseller = rawBestseller;
      } else if (rawBestseller is String) {
        bestseller = rawBestseller.toLowerCase() == 'true' || rawBestseller == '1';
      } else if (rawBestseller is num) {
        bestseller = rawBestseller == 1;
      }
    }

    return Product(
      id: json['id'],
      name: json['name']?.toString() ?? 'Unknown Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'General',
      imageUrl: json['image']?.toString(), 
      isBestseller: bestseller,
      description: json['description']?.toString(),
    );
  }

  String getFullImageUrl(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    if (imageUrl!.startsWith('http')) return imageUrl!;
    return '$baseUrl/assets/$imageUrl';
  }
}
