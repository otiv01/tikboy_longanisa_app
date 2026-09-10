import 'dart:convert';

class OrderModel {
  final String? id;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;

  OrderModel({
    this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'total': totalAmount,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItem> itemsList = [];
    
    if (rawItems != null) {
      if (rawItems is List) {
        itemsList = rawItems.map((i) => OrderItem.fromJson(i)).toList();
      } else if (rawItems is String) {
        try {
          final decoded = jsonDecode(rawItems);
          if (decoded is List) {
            itemsList = decoded.map((i) => OrderItem.fromJson(i)).toList();
          }
        } catch (e) {
          // Fallback if JSON string is malformed
        }
      }
    }

    return OrderModel(
      id: json['id'].toString(),
      totalAmount: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      date: json['date_created'] != null 
          ? DateTime.parse(json['date_created']) 
          : DateTime.now(),
      items: itemsList,
    );
  }
}

class OrderItem {
  final String? productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id']?.toString(),
      name: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
