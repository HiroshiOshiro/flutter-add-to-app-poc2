import Flutter
import UIKit

/// Flutter側の Service に対応するネイティブ側のハンドラ。
///
/// チャンネルは画面単位ではなく機能単位で切る。画面ごとにチャンネルを
/// 用意すると画面数だけハンドラが増えるが、機能単位なら画面が増えても
/// ハンドラは増えず、機能がFlutterへ移るたびに減っていく。
enum NativeServices {

    private static let channelNavigation = "com.example.legacyapp/navigation"
    private static let channelLegacyStore = "com.example.legacyapp/legacy_store"

    static func attach(to engine: FlutterEngine, presenting host: UIViewController) {
        attachNavigation(engine: engine, host: host)
        attachLegacyStore(engine: engine)
    }

    /// Flutterの領域から出る遷移をネイティブが引き受ける。
    private static func attachNavigation(engine: FlutterEngine, host: UIViewController) {
        let channel = FlutterMethodChannel(
            name: channelNavigation,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak host] call, result in
            guard let host else {
                result(FlutterError(code: "no_host", message: "Host was released", details: nil))
                return
            }
            switch call.method {
            case "openNative":
                guard let arguments = call.arguments as? [String: Any],
                      let screen = arguments["route"] as? String else {
                    result(FlutterError(code: "invalid_argument",
                                        message: "route is required",
                                        details: nil))
                    return
                }
                guard let next = NativeRouter.viewController(for: screen) else {
                    result(FlutterError(code: "unknown_route",
                                        message: "No native screen for \(screen)",
                                        details: nil))
                    return
                }
                // Flutter画面をスタックに残さず置き換える。ネイティブ⇔Flutterを
                // 往復したときに戻る先が二重にならないようにする。
                if let navigation = host.navigationController {
                    var stack = navigation.viewControllers
                    if let index = stack.firstIndex(of: host) {
                        stack.replaceSubrange(index..<stack.count, with: [next])
                        navigation.setViewControllers(stack, animated: true)
                    } else {
                        navigation.pushViewController(next, animated: true)
                    }
                }
                result(nil)

            case "close":
                host.navigationController?.popViewController(animated: true)
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// 移行前のネイティブコードが保存したローカルデータを読ませる。
    ///
    /// Flutterのキーバリューストア用プラグインは既定ではキーにプレフィックスを
    /// 付けるため、ここにある既存の値は見えない。プレフィックスを外して直接
    /// 読むこともできるが、そうすると同じデータを両側から読み書きできてしまう。
    /// 所有者はネイティブのままにして、読み出しだけをこのチャンネルで提供する。
    private static func attachLegacyStore(engine: FlutterEngine) {
        let channel = FlutterMethodChannel(
            name: channelLegacyStore,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "readStrings":
                guard let arguments = call.arguments as? [String: Any],
                      let keys = arguments["keys"] as? [String] else {
                    result(FlutterError(code: "invalid_argument",
                                        message: "keys is required",
                                        details: nil))
                    return
                }
                let defaults = UserDefaults.standard
                var values: [String: String] = [:]
                for key in keys {
                    if let value = defaults.string(forKey: key) {
                        values[key] = value
                    }
                }
                result(values)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
