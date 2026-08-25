import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tikboy_longanisa_app/main.dart';
import 'package:tikboy_longanisa_app/providers/auth_provider.dart';
import 'package:tikboy_longanisa_app/providers/cart_provider.dart';

void main() {
  testWidgets('shows the sign-in screen for a signed-out user', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const TikboyApp(),
      ),
    );

    expect(find.text('Registered Email Address'), findsOneWidget);
  });
}
