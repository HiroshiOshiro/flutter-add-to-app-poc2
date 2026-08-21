import 'package:flutter/services.dart';

/// Flutterの領域**から出る**ときにネイティブへ依頼するチャンネル。
///
/// チャンネルは画面単位ではなく機能単位で切る。画面ごとにチャンネルを
/// 用意すると画面数だけハンドラが増えていくが、機能単位であれば画面が
/// 増えてもチャンネルは増えず、逆に機能がFlutterへ移るたびに減っていく。
/// 全面移行の完了時点でこのチャンネル自体が不要になるのが正しい方向。
class NavigationChannel {
  const NavigationChannel([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'com.example.legacyapp/navigation';

  final MethodChannel _channel;

  /// まだFlutter化されていないネイティブ画面へ遷移する。
  ///
  /// [route] はネイティブ側が解釈する論理的な画面名。Flutter側は遷移方法
  /// （Activityの起動かpushViewControllerか）を知らない。
  Future<void> openNative(String route, {Map<String, Object?>? arguments}) {
    return _channel.invokeMethod<void>('openNative', <String, Object?>{
      'route': route,
      'arguments': ?arguments,
    });
  }

  /// Flutterを表示しているネイティブ側のコンテナを閉じて、元の画面へ戻る。
  Future<void> close() => _channel.invokeMethod<void>('close');
}
