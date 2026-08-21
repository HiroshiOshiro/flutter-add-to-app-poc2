import 'package:flutter/foundation.dart';

/// アプリ全体で使うロギングの入口。
///
/// テーマと同じ理由で、移行の初期からDart側に置く。ここを1箇所にしておけば、
/// 実際の分析基盤（ネイティブSDKへのブリッジでも、Dart製のクライアントでも）
/// を後から差し替えるときに呼び出し側を触らずに済む。
abstract class AppLogger {
  void debug(String message);
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// 既定の実装。デバッグビルドでのみ標準出力へ流す。
class DebugPrintLogger implements AppLogger {
  const DebugPrintLogger({this.tag = 'legacyapp'});

  final String tag;

  @override
  void debug(String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR $message${error == null ? '' : ': $error'}');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }
}
