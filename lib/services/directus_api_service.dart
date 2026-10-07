import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class DirectusApiService {
  final String baseUrl = ''; 
  final _supabase = Supabase.instance.client;

  // 1. Login (Using Supabase Auth)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (res.session != null) {
        return {'access_token': res.session!.accessToken};
      }
      throw Exception('Login failed');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // 2. Register (Using Supabase Auth)
  Future<void> register(String email, String password, String firstName) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName},
      );
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // 3. Fetch Products from Supabase (with offline local fallback)
  Future<List<Product>> fetchProducts() async {
    try {
      final data = await _supabase.from('products').select();
      if ((data as List).isEmpty) {
        return _getLocalFallbackProducts();
      }
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching products from Supabase (using offline fallback): $e');
      return _getLocalFallbackProducts();
    }
  }

  List<Product> _getLocalFallbackProducts() {
    return [
      Product(
        id: 'longanisa_pork',
        name: 'Longanisa (Pork)',
        price: 85.0,
        category: 'Longanisa',
        imageUrl: 'assets/img_1.jpg',
        description: 'Regular: ₱85/₱170 | Spicy: ₱90/₱180 | Sweet: ₱200/kilo',
        isBestseller: true,
      ),
      Product(
        id: 'longanisa_chicken',
        name: 'Longanisa Chicken',
        price: 75.0,
        category: 'Chicken',
        imageUrl: 'assets/img_1.jpg',
        description: 'Small: ₱75 | Big: ₱150',
        isBestseller: true,
      ),
      Product(
        id: 'embutido',
        name: 'Embutido',
        price: 50.0,
        category: 'Embutido',
        imageUrl: 'assets/embutido.png',
        description: 'Small: ₱50 | Big: ₱100',
        isBestseller: false,
      ),
      Product(
        id: 'chili_oil',
        name: 'Crispy Chili Garlic Oil',
        price: 150.0,
        category: 'Condiments',
        imageUrl: 'assets/chiliOIL.jpg',
        description: 'Standard size: ₱150',
        isBestseller: false,
      ),
    ];
  }

  // 4. Create Order in Supabase
  Future<void> createOrder(OrderModel order, String? token) async {
    try {
      await _supabase.from('orders').insert({
        'total': order.totalAmount,
        'status': order.status,
        'address': order.address,
        'items': order.items.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to place order in Supabase: $e');
    }
  }

  // 5. Fetch Orders from Supabase
  Future<List<OrderModel>> fetchOrders(String? token) async {
    try {
      final data = await _supabase.from('orders').select().order('date_created', ascending: false);
      return (data as List).map((json) => OrderModel.fromJson({
        'id': json['id'],
        'total': json['total'],
        'status': json['status'],
        'address': json['address'],
        'items': json['items'],
        'date_created': json['date_created'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to load orders from Supabase: $e');
    }
  }

  // 6. Update Order Status in Supabase (e.g. Request Refund)
  Future<void> updateOrderStatus(String orderId, String newStatus, String? token) async {
    try {
      await _supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status in Supabase: $e');
    }
  }
}
