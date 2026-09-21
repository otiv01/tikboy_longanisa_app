import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressItem {
  final String id;
  final String label;
  final String address;
  final bool isDefault;

  AddressItem({
    required this.id,
    required this.label,
    required this.address,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'isDefault': isDefault,
      };

  factory AddressItem.fromJson(Map<String, dynamic> json) => AddressItem(
        id: json['id'],
        label: json['label'],
        address: json['address'],
        isDefault: json['isDefault'] ?? false,
      );
}

class AddressProvider with ChangeNotifier {
  List<AddressItem> _addresses = [];

  AddressProvider() {
    _loadAddresses();
  }

  List<AddressItem> get addresses => [..._addresses];

  Future<void> addAddress(String label, String address) async {
    final newItem = AddressItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      address: address,
      isDefault: _addresses.isEmpty, // Make default if it's the first address
    );
    _addresses.add(newItem);
    notifyListeners();
    await _saveAddresses();
  }

  Future<void> deleteAddress(String id) async {
    _addresses.removeWhere((item) => item.id == id);
    notifyListeners();
    await _saveAddresses();
  }

  Future<void> setDefault(String id) async {
    _addresses = _addresses.map((item) {
      return AddressItem(
        id: item.id,
        label: item.label,
        address: item.address,
        isDefault: item.id == id,
      );
    }).toList();
    notifyListeners();
    await _saveAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_addresses');
    if (data != null) {
      final List decoded = json.decode(data);
      _addresses = decoded.map((item) => AddressItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_addresses.map((item) => item.toJson()).toList());
    await prefs.setString('saved_addresses', encoded);
  }
}
