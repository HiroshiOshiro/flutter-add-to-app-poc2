import UIKit

/// 論理的な画面名から、実際に開くべき画面を決める。
///
/// ネイティブ側もFlutter側も「確認画面へ行きたい」としか言わず、それが
/// Flutter実装なのかネイティブ実装なのかは `FeatureFlags` を見てここが決める。
/// 呼び出し側がフラグを直接見る作りにすると、Flutter化するたびに分岐が
/// アプリ中に散らばるため、判断を1箇所に集約する。
@objc final class NativeRouter: NSObject {

    /// ネイティブ側・Flutter側で共有する論理的な画面名。
    @objc static let screenConfirm = "confirm"
    @objc static let screenComplete = "complete"

    /// Flutter側のルート名。Dartの `AppRoutes` と対応させる。
    private static let flutterRoutes: [String: String] = [
        screenConfirm: "/confirm"
    ]

    /// 画面名に対応するフラグ名。
    private static let screenFlags: [String: String] = [
        screenConfirm: FeatureFlags.screenConfirm
    ]

    @objc static func viewController(for screen: String) -> UIViewController? {
        if let route = flutterRoutes[screen],
           let flag = screenFlags[screen],
           FeatureFlags.useFlutter(flag) {
            return FlutterHost.viewController(route: route)
        }
        return nativeViewController(for: screen)
    }

    /// まだFlutter化していない、あるいはフラグで無効化されている画面。
    private static func nativeViewController(for screen: String) -> UIViewController? {
        switch screen {
        case screenConfirm:
            return ConfirmViewController()
        case screenComplete:
            return CompleteViewController()
        default:
            return nil
        }
    }
}
