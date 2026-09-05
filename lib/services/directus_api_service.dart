import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class DirectusApiService {
  // ⚠️ Replace with your actual Computer's IP Address (e.g., '192.168.x.x')
  final String baseUrl = 'http://localhost:8055';

  // 1. Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 2. Register
  Future<void> register(String email, String password, String firstName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'role': '8d43c22b-586e-4f36-9304-4c125197825d', // TODO: You might need to change this to your "Customer" role ID
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 3. Fetch Products
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items/products'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        final List<dynamic> data = decodedResponse['data'];
        
        return data.map((json) => Product.fromJson(json)).toList(); 
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
