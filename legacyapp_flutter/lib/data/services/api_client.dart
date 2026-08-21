import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/logger.dart';

/// 通信の共通入口。
///
/// 既存アプリの通信基盤（共通ヘッダ・認証・エラー整形）をネイティブ側に
/// 温存してMethodChannelで呼び出す作りにすると、そのブリッジは全画面が
/// 使うことになり、捨てコードが最大化する。全面移行を前提にするなら、
/// 通信は早い段階でDart側に寄せるのが結果的に近道になる。
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    AppLogger logger = const DebugPrintLogger(),
  })  : _http = httpClient ?? http.Client(),
        _logger = logger;

  final http.Client _http;
  final AppLogger _logger;

  /// 共通ヘッダ。認証トークンなどが必要になったらここに集約する。
  Map<String, String> get _commonHeaders => const <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };

  /// JSONをPOSTし、2xxが返ったかどうかを返す。
  Future<bool> postJson(Uri uri, Map<String, Object?> body) async {
    _logger.debug('POST $uri');
    try {
      final http.Response response = await _http.post(
        uri,
        headers: _commonHeaders,
        body: jsonEncode(body),
      );
      final bool ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) _logger.error('POST $uri failed: ${response.statusCode}');
      return ok;
    } catch (error, stackTrace) {
      _logger.error('POST $uri threw', error: error, stackTrace: stackTrace);
      return false;
    }
  }
}
