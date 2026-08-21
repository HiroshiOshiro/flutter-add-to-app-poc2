import 'package:flutter/services.dart';

/// 移行前のネイティブコードが保存したローカルデータを読むためのチャンネル。
///
/// Flutterのキーバリューストア用プラグインは、既定では全キーに専用の
/// プレフィックスを付け、Androidでは保存先ファイルもFlutter専用のものに
/// なるため、**ネイティブが既に書いた値は見えない**。プレフィックスを外して
/// 直接読むこともできるが、そうすると同じデータをネイティブとFlutterの
/// 両方から読み書きできてしまい、どちらが最新か分からない状態が移行完了まで
/// 残る。
///
/// そのため移行期間中は「所有者はネイティブのまま、Flutterは読むだけ」と
/// 決め、その受け渡しをこのチャンネル1本に集約する。Flutterへ完全に移した
/// データはここから外していき、最終的にこのチャンネルごと消える。
class LegacyStoreChannel {
  const LegacyStoreChannel([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'com.example.legacyapp/legacy_store';

  final MethodChannel _channel;

  /// 指定したキーの値をネイティブのキーバリューストアから読む。
  ///
  /// 値が存在しないキーは戻り値に含まれない。
  Future<Map<String, String>> readStrings(List<String> keys) async {
    final Map<Object?, Object?>? raw =
        await _channel.invokeMethod<Map<Object?, Object?>>(
      'readStrings',
      <String, Object?>{'keys': keys},
    );
    if (raw == null) return const <String, String>{};
    return raw.map(
      (Object? key, Object? value) =>
          MapEntry<String, String>(key! as String, value! as String),
    );
  }
}
