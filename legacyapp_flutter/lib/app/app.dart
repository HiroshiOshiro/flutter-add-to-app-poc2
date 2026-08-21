import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

/// Flutter側のアプリシェル。
///
/// エントリポイントは `main()` ひとつだけにし、**どの画面を表示するかは
/// ネイティブから渡される初期ルートで決める**。画面ごとにDartのエントリ
/// ポイントを増やす方式だと、画面が増えるたびにネイティブ側の起動コードも
/// 増え、全面移行の途中で破綻する。
///
/// 画面遷移の所有権もここ（Flutterの[Navigator]）にある。Flutter化された
/// 画面同士の遷移はネイティブを経由しないため、画面が増えてもネイティブ⇔
/// Flutterの境界は増えない。
class App extends StatelessWidget {
  const App({
    super.key,
    required this.initialRoute,
    required this.routes,
  });

  /// ネイティブから渡された初期ルート。
  final String initialRoute;

  /// 各featureが提供する画面。featureを追加するときはここへ登録する。
  final Map<String, WidgetBuilder> routes;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<Object?> _onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute<Object?>(builder: builder, settings: settings);
    }
    // 未登録のルートで起動された場合。ネイティブ側のルート名とAppRoutesの
    // 定義がずれたときに無言で白画面になるのを避けるため、明示的に出す。
    return MaterialPageRoute<Object?>(
      settings: settings,
      builder: (_) => _UnknownRouteScreen(routeName: settings.name),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final String name = routeName ?? AppRoutes.root;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No Flutter screen is registered for "$name"',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
