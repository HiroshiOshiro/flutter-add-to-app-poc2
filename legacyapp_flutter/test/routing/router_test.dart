import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legacyapp_flutter/main.dart';
import 'package:legacyapp_flutter/routing/router.dart';
import 'package:legacyapp_flutter/routing/routes.dart';

void main() {
  Widget screen(String label) => Scaffold(body: Text(label));

  testWidgets('shows the screen registered for the initial route',
      (tester) async {
    await tester.pumpWidget(MainApp(
      initialRoute: AppRoutes.confirm,
      router: AppRouter(<String, WidgetBuilder>{
        AppRoutes.confirm: (_) => screen('confirm screen'),
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('confirm screen'), findsOneWidget);
  });

  testWidgets('navigates between Flutter screens without leaving Flutter',
      (tester) async {
    const String next = '/next';

    await tester.pumpWidget(MainApp(
      initialRoute: AppRoutes.confirm,
      router: AppRouter(<String, WidgetBuilder>{
        AppRoutes.confirm: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(next),
                child: const Text('go next'),
              ),
            ),
        next: (_) => screen('next screen'),
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('go next'));
    await tester.pumpAndSettle();

    expect(find.text('next screen'), findsOneWidget);
  });

  testWidgets('falls back to a visible message for an unregistered route',
      (tester) async {
    await tester.pumpWidget(const MainApp(
      initialRoute: '/not-registered',
      router: AppRouter(<String, WidgetBuilder>{}),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('No Flutter screen is registered for "/not-registered"'),
      findsOneWidget,
    );
  });
}
