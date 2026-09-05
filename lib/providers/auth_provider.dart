import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/directus_api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _accessToken;
  final _apiService = DirectusApiService();

  bool get isAuthenticated => _isAuthenticated;
  String? get accessToken => _accessToken;

  AuthProvider() {
    _loadSession();
  }

  // Check if user is already logged in on app start
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _isAuthenticated = _accessToken != null;
    notifyListeners();
  }

  // Login via Directus
  Future<void> login(String email, String password) async {
    try {
      final data = await _apiService.login(email, password);
      _accessToken = data['access_token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  // Register via Directus
  Future<void> register(String email, String password, String name) async {
    try {
      await _apiService.register(email, password, name);
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
    _isAuthenticated = false;
    notifyListeners();
  }
}
