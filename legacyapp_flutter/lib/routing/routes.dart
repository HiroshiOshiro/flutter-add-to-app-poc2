/// Flutter側が担当する画面のルート名。
///
/// ネイティブはFlutterを起動するときにこの文字列を初期ルートとして渡す。
/// 画面がFlutter化されるたびにここへ1行足していき、逆にネイティブ側には
/// 画面ごとの起動コードを増やさない、というのが本構成の狙い。
class AppRoutes {
  const AppRoutes._();

  /// Flutter側にまだ画面がない状態でエンジンだけ起動されたときの行き先。
  static const String root = '/';

  /// 入力内容の確認画面。
  static const String confirm = '/confirm';
}
