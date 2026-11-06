import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoyaltyHistoryItem {
  final String title;
  final String points;
  final String date;
  final Color color;

  LoyaltyHistoryItem({
    required this.title,
    required this.points,
    required this.date,
    required this.color,
  });
}

class LoyaltyProvider with ChangeNotifier {
  int _points = 320;
  final List<LoyaltyHistoryItem> _history = [
    LoyaltyHistoryItem(title: 'Order #TK1024', points: '+45 pts', date: 'Mar 28, 2026', color: Colors.green),
    LoyaltyHistoryItem(title: 'Product Review', points: '+5 pts', date: 'Mar 25, 2026', color: Colors.green),
    LoyaltyHistoryItem(title: 'Redeemed Voucher', points: '-500 pts', date: 'Mar 10, 2026', color: Colors.red),
    LoyaltyHistoryItem(title: 'Order #TK0988', points: '+32 pts', date: 'Mar 05, 2026', color: Colors.green),
  ];

  int get points => _points;
  List<LoyaltyHistoryItem> get history => _history;

  LoyaltyProvider() {
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('loyalty_points') ?? 320;
    notifyListeners();
  }

  Future<void> addPointsForOrder(double totalAmount) async {
    // Earn 10 points per every ₱100 spent
    int earnedPoints = (totalAmount / 100 * 10).round();
    if (earnedPoints < 1) earnedPoints = 1;

    _points += earnedPoints;

    final now = DateTime.now();
    final dateStr = '${_getMonthName(now.month)} ${now.day}, ${now.year}';
    _history.insert(
      0,
      LoyaltyHistoryItem(
        title: 'Completed Order',
        points: '+$earnedPoints pts',
        date: dateStr,
        color: Colors.green,
      ),
    );

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('loyalty_points', _points);
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
