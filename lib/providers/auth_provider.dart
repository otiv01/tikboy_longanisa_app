import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/directus_api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _accessToken;
  String _role = 'customer';
  final _apiService = DirectusApiService();

  bool get isAuthenticated => _isAuthenticated;
  String? get accessToken => _accessToken;
  String get role => _role;

  AuthProvider() {
    _loadSession();
  }

  // Check if user is already logged in on app start
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _isAuthenticated = _accessToken != null;
    if (_isAuthenticated) {
      await fetchUserRole();
    }
    notifyListeners();
  }

  Future<void> fetchUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Check user metadata first as immediate source of truth
        final metaRole = user.userMetadata?['role']?.toString().toLowerCase();
        if (metaRole != null && metaRole.isNotEmpty) {
          _role = metaRole;
        }

        // 2. Fetch from profiles table
        final res = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
            
        if (res != null && res['role'] != null) {
          final dbRole = res['role'].toString().toLowerCase();
          if (dbRole.isNotEmpty) {
            _role = dbRole;
          }
        } else if (_role == 'rider' || _role == 'admin') {
          // Sync to DB profile if missing
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'role': _role,
            'full_name': user.userMetadata?['full_name'] ?? 'User',
          });
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
  }

  // Login via Directus
  Future<void> login(String email, String password) async {
    try {
      final data = await _apiService.login(email, password);
      _accessToken = data['access_token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      
      _isAuthenticated = true;
      await fetchUserRole();
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  // Register via Directus
  Future<void> register(String email, String password, String name, {String role = 'customer'}) async {
    try {
      await _apiService.register(email, password, name, role: role);
      // After registration, we usually ask user to login
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _accessToken = null;
    _role = 'customer';
    _isAuthenticated = false;
    notifyListeners();
  }
}
