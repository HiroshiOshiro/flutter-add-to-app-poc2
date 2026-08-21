import 'package:flutter/material.dart';

import 'routes.dart';

/// Flutter化済みの画面の登録表。
///
/// 画面をFlutter化するときに触るのは、[AppRoutes]へのルート名追加と
/// この表への1行追加だけ。ネイティブ側には画面ごとの起動コードを追加しない。
///
/// Phase 0（土台のみ）の時点では空。
Map<String, WidgetBuilder> registeredScreens() {
  return <String, WidgetBuilder>{};
}

/// ルート名から画面を解決する。
///
/// 画面遷移の所有権はFlutter側にある。Flutter化済みの画面同士の遷移は
/// ネイティブを経由しないため、画面が増えてもネイティブ⇔Flutterの境界は
/// 増えない。ネイティブへの遷移依頼が必要になるのは、Flutterの領域から
/// 出るときだけ（`NavigationService`）。
class AppRouter {
  const AppRouter(this.screens);

  final Map<String, WidgetBuilder> screens;

  Route<Object?> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = screens[settings.name];
    if (builder != null) {
      return MaterialPageRoute<Object?>(builder: builder, settings: settings);
    }
    // 未登録のルートで起動された場合。ネイティブ側のルート名とAppRoutesの
    // 定義がずれたときに無言で白画面になるのを避けるため、明示的に出す。
    return MaterialPageRoute<Object?>(
      settings: settings,
      builder: (_) => UnknownRouteScreen(routeName: settings.name),
    );
  }
}

/// ルート名に対応する画面が登録されていないことを画面上に示す。
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.routeName});

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
