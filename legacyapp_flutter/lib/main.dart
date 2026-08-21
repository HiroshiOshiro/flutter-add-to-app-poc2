import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/router.dart';
import 'ui/core/themes/app_theme.dart';

/// アプリ唯一のDartエントリポイント。
///
/// 画面ごとにエントリポイントを増やす方式（`confirmMain()` / `musicMain()`
/// のような形）は、1画面だけをFlutter化する段階では素直に見えるが、
/// 画面が増えるたびにネイティブ側の起動コードとエンジンの管理コードが
/// 増えていく。全面移行を前提にするなら、エントリポイントは最初から1つに
/// 固定し、**どの画面を出すかはネイティブから渡される初期ルートで決める**。
///
/// ネイティブ側はエンジン起動時に初期ルートを指定する。ここではその値を
/// [PlatformDispatcher.defaultRouteName] から受け取っている。
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: MainApp(
        initialRoute: PlatformDispatcher.instance.defaultRouteName,
        router: AppRouter(registeredScreens()),
      ),
    ),
  );
}

/// Flutter側のアプリシェル。
class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.initialRoute,
    required this.router,
  });

  /// ネイティブから渡された初期ルート。
  final String initialRoute;

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateInitialRoutes: router.onGenerateInitialRoutes,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
