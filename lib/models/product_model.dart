class Product {
  final int id;
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

  // Factory to convert Directus REST API JSON into Product model
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      category: json['category'] ?? 'General',
      imageUrl: json['image_url'], // Field name in Directus collection
      isBestseller: json['is_bestseller'] ?? false,
      description: json['description'],
    );
  }
}