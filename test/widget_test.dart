import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tikboy_longganisa_mobile/main.dart';
import 'package:tikboy_longganisa_mobile/providers/auth_provider.dart';
import 'package:tikboy_longganisa_mobile/providers/cart_provider.dart';

void main() {
  testWidgets('Tikboy App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const TikboyApp(),
      ),
    );

    // Verify that we start on the Landing Screen
    expect(find.text('Tikboy Longganisa'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Tap the 'Sign In' button and trigger a frame.
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify that we are now on the Sign In Screen
    expect(find.text('Sign in to continue ordering'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });
}
