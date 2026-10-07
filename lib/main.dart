import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/address_provider.dart';
import 'main_navigation.dart';
import 'screens/auth/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eczdqewxpxaaqhsnbvlp.supabase.co',
    anonKey: 'sb_publishable_-jrdjAsOBbWnE2SHnb3TAg_z-Hvj1_s',
  );

  // Test Supabase Database Connection on Startup
  try {
    final response = await Supabase.instance.client.from('products').select().limit(1);
    debugPrint('✅ Supabase connected successfully! Response: $response');
  } catch (e) {
    debugPrint('❌ Supabase connection error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: const TikboyApp(),
    ),
  );
}

class TikboyApp extends StatelessWidget {
  const TikboyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tikboy Longganisa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return auth.isAuthenticated ? const MainNavigationScreen() : const LandingScreen();
        },
      ),
    );
  }
}
