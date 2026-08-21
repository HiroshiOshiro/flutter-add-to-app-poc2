import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/route_table.dart';

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
      child: App(
        initialRoute: PlatformDispatcher.instance.defaultRouteName,
        routes: buildAppRoutes(),
      ),
    ),
  );
}
