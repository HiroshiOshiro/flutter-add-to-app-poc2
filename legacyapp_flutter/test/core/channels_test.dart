import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legacyapp_flutter/core/channels/legacy_store_channel.dart';
import 'package:legacyapp_flutter/core/channels/navigation_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  /// ネイティブ側の代わりに応答するfake。
  void handle(MethodChannel channel, Object? Function(MethodCall) respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return respond(call);
    });
  }

  setUp(() => calls = <MethodCall>[]);

  group('NavigationChannel', () {
    const MethodChannel channel =
        MethodChannel(NavigationChannel.channelName);

    test('openNative sends the route and arguments', () async {
      handle(channel, (_) => null);

      await const NavigationChannel(channel)
          .openNative('complete', arguments: <String, Object?>{'id': 1});

      expect(calls.single.method, 'openNative');
      expect(calls.single.arguments, <String, Object?>{
        'route': 'complete',
        'arguments': <String, Object?>{'id': 1},
      });
    });

    test('openNative omits arguments when there are none', () async {
      handle(channel, (_) => null);

      await const NavigationChannel(channel).openNative('complete');

      expect(calls.single.arguments, <String, Object?>{'route': 'complete'});
    });

    test('close asks the native container to close', () async {
      handle(channel, (_) => null);

      await const NavigationChannel(channel).close();

      expect(calls.single.method, 'close');
    });
  });

  group('LegacyStoreChannel', () {
    const MethodChannel channel =
        MethodChannel(LegacyStoreChannel.channelName);

    test('readStrings returns the values the native side reports', () async {
      handle(channel, (_) => <Object?, Object?>{'draft_name': 'Taro'});

      final Map<String, String> values =
          await const LegacyStoreChannel(channel)
              .readStrings(<String>['draft_name', 'draft_email']);

      expect(calls.single.method, 'readStrings');
      expect(calls.single.arguments, <String, Object?>{
        'keys': <String>['draft_name', 'draft_email'],
      });
      expect(values, <String, String>{'draft_name': 'Taro'});
    });

    test('readStrings treats a null reply as no values', () async {
      handle(channel, (_) => null);

      final Map<String, String> values =
          await const LegacyStoreChannel(channel).readStrings(<String>['x']);

      expect(values, isEmpty);
    });
  });
}
