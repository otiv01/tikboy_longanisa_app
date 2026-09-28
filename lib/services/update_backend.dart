import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'http://192.168.1.77:8055';
  
  // 🔑 IF YOU HAVE A STATIC TOKEN, PASTE IT HERE:
  const String staticToken = ''; 

  final List<Map<String, dynamic>> newProducts = [
    {'name': 'Longganisa Regular (Small)', 'price': 85, 'category': 'Longganisa', 'description': 'Per Dozen', 'is_bestseller': true},
    {'name': 'Longganisa Regular (Big)', 'price': 170, 'category': 'Longganisa', 'description': 'Per Dozen', 'is_bestseller': false},
    {'name': 'Longganisa Spicy (Small)', 'price': 90, 'category': 'Longganisa', 'description': 'Per Dozen', 'is_bestseller': true},
    {'name': 'Longganisa Spicy (Big)', 'price': 180, 'category': 'Longganisa', 'description': 'Per Dozen', 'is_bestseller': false},
    {'name': 'Longganisa Sweet', 'price': 200, 'category': 'Longganisa', 'description': 'Per Kilo', 'is_bestseller': true},
    {'name': 'Embutido (Small)', 'price': 50, 'category': 'Embutido', 'description': '', 'is_bestseller': false},
    {'name': 'Embutido (Big)', 'price': 100, 'category': 'Embutido', 'description': '', 'is_bestseller': false},
    {'name': 'Crispy Chili Garlic Oil', 'price': 150, 'category': 'Condiments', 'description': '', 'is_bestseller': true},
    {'name': 'Chicken Longganisa (Small)', 'price': 75, 'category': 'Chicken', 'description': 'Regular', 'is_bestseller': false},
    {'name': 'Chicken Longganisa (Big)', 'price': 150, 'category': 'Chicken', 'description': 'Regular', 'is_bestseller': false},
  ];

  print('🚀 Starting Backend Update...');

  final headers = {
    'Content-Type': 'application/json',
    if (staticToken.isNotEmpty) 'Authorization': 'Bearer $staticToken',
  };

  try {
    // 1. Get all current products
    final getResponse = await http.get(Uri.parse('$baseUrl/items/products'), headers: headers);
    if (getResponse.statusCode == 200) {
      final List ids = (json.decode(getResponse.body)['data'] as List).map((p) => p['id']).toList();
      
      // 2. Delete old products
      if (ids.isNotEmpty) {
        print('🗑️ Deleting ${ids.length} old products...');
        final delRes = await http.delete(
          Uri.parse('$baseUrl/items/products'),
          headers: headers,
          body: json.encode(ids),
        );
        if (delRes.statusCode != 200 && delRes.statusCode != 204) {
          print('⚠️ Warning: Delete failed: ${delRes.body}');
        }
      }
    }

    // 3. Add new products
    print('📦 Uploading new products...');
    for (var product in newProducts) {
      final res = await http.post(
        Uri.parse('$baseUrl/items/products'),
        headers: headers,
        body: json.encode(product),
      );
      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 201) {
        print('✅ Added: ${product['name']}');
      } else {
        print('❌ Failed to add ${product['name']}: ${res.body}');
      }
    }

    print('\n✨ Backend update complete! Hot Restart your app to see the changes.');
  } catch (e) {
    print('🚨 Error connecting to Directus: $e');
  }
}
