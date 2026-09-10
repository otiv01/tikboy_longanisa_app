import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/order_model.dart';

class DirectusApiService {
  // 📱 Using your correct local Wi-Fi IP address
  final String baseUrl = 'http://192.168.1.19:8055'; 

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
          'role': '1919cd62-03e5-4b2e-899f-928a0c2e1558',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        final error = json.decode(response.body);
        final errorMessage = error['errors']?[0]['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
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

  // 4. Create Order
  Future<void> createOrder(OrderModel order, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items/orders'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(order.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        final error = json.decode(response.body);
        final errorCode = error['errors']?[0]['extensions']?['code'];
        if (errorCode == 'TOKEN_EXPIRED') {
          throw Exception('SESSION_EXPIRED');
        }
        throw Exception(error['errors']?[0]['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  // 5. Fetch Orders
  Future<List<OrderModel>> fetchOrders(String? token) async {
    try {
      // ⚠️ Removed sort to avoid the date_created 403 error
      final response = await http.get(
        Uri.parse('$baseUrl/items/orders'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        final message = errorBody['errors']?[0]['message'] ?? 'Unknown error';
        throw Exception('Failed to load orders: ${response.statusCode} - $message');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
