import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectusApiService {
  // Replace with your actual application server IP/domain hosting Directus
  final String baseUrl = 'http://YOUR_SERVER_IP:8055';

  // Fetches live product data to prevent ordering out-of-stock items
  Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items/products'));
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse['data']; 
      } else {
        throw Exception('Failed to load products from server');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}