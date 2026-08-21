import 'package:flutter/material.dart';

/// アプリ全体で共有するテーマ。
///
/// 移行の初期段階から**Dart側に置く**のが要点。ネイティブ側のテーマ定義を
/// MethodChannelで問い合わせる作りにすると、そのブリッジは全面移行の完了時に
/// すべて捨てることになる。見た目の不統一は移行中に最も目立つ問題なので、
/// 早い段階でDartを正とし、ネイティブ側をそれに合わせていく。
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF3F51B5);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      );
}
