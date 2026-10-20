import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main_navigation.dart';
import 'landing_screen.dart';
import '../rider/rider_home_screen.dart';
import '../admin/admin_notice_screen.dart';

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) {
          return const LandingScreen();
        }
        if (auth.role == 'rider') {
          return const RiderHomeScreen();
        } else if (auth.role == 'admin') {
          return const AdminNoticeScreen();
        } else {
          return const MainNavigationScreen();
        }
      },
    );
  }
}
