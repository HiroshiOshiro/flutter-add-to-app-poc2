import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// 検証用の最小構成。
///
/// ガイド「6. ステップ3」が書いている「初期ルートで表示する画面を決める」を
/// そのまま実装している。**ガイドが対処として挙げている
/// `onGenerateInitialRoutes` は、意図的にまだ入れていない**（検証点E）。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: PlatformDispatcher.instance.defaultRouteName,
      // ガイド「初期ルートを渡すときの落とし穴」の対処。
      onGenerateInitialRoutes: (String initialRoute) => <Route<void>>[
        _routeFor(RouteSettings(name: initialRoute)),
      ],
      onGenerateRoute: (RouteSettings settings) {
        return _routeFor(settings);
      },
    );
  }

  MaterialPageRoute<void> _routeFor(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Flutter Screen')),
        body: Center(child: Text('route: ${settings.name}')),
      ),
    );
  }
}
