import 'package:flutter/material.dart';

/// Flutter化済みの画面の登録表。
///
/// 画面をFlutter化するときに触るのは、[AppRoutes]へのルート名追加と
/// この表への1行追加だけ。ネイティブ側には画面ごとの起動コードを追加しない。
///
/// Phase 0（土台のみ）の時点では空。
Map<String, WidgetBuilder> buildAppRoutes() {
  return <String, WidgetBuilder>{};
}
