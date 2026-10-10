import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileProvider with ChangeNotifier {
  String _name = 'Customer Name';
  String _email = 'customer@email.com';
  String _phone = '+63 912 345 6789';
  String _address = 'Lucban, Quezon Province';
  String _imageUrl = '';

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get imageUrl => _imageUrl;

  UserProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('profile_name') ?? 'Customer Name';
    _email = prefs.getString('profile_email') ?? 'customer@email.com';
    _phone = prefs.getString('profile_phone') ?? '+63 912 345 6789';
    _address = prefs.getString('profile_address') ?? 'Lucban, Quezon Province';
    _imageUrl = prefs.getString('profile_image') ?? '';
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    required String imageUrl,
  }) async {
    _name = name;
    _phone = phone;
    _address = address;
    _imageUrl = imageUrl;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _name);
    await prefs.setString('profile_phone', _phone);
    await prefs.setString('profile_address', _address);
    await prefs.setString('profile_image', _imageUrl);
  }
}
