import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Order Delivered!',
      message: 'Your order #TK1024 has been successfully delivered. Enjoy your longganisa!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.order,
    ),
    NotificationModel(
      id: '2',
      title: 'Hot Deal! 🔥',
      message: 'Get 20% OFF on all Embutido products this weekend. Don\'t miss out!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.promo,
    ),
    NotificationModel(
      id: '3',
      title: 'Welcome to Tikboy!',
      message: 'Thanks for joining us. Start exploring our authentic flavors now.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.account,
    ),
  ];

  List<NotificationModel> get notifications => [..._notifications];

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
