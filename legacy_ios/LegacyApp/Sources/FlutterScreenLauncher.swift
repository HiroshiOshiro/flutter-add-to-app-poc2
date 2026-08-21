import Flutter
import FlutterPluginRegistrant
import UIKit

/// ガイド「6. ステップ3: Flutter画面を表示する」の検証用。
///
/// ガイドはiOS側について「`FlutterViewController` を表示する。エンジンを
/// どう用意するかはAndroidと同じ選択になる」としか書いておらず、**コードの
/// スニペットが1つも無い**。Androidと同じく `FlutterEngineGroup` を使う形を
/// 公式APIから自分で書いた。
@objc final class FlutterScreenLauncher: NSObject {

    private static let engineGroup = FlutterEngineGroup(
        name: "legacyapp_engine_group",
        project: nil
    )

    @objc static func viewController(route: String) -> UIViewController {
        let engine = engineGroup.makeEngine(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: route
        )
        GeneratedPluginRegistrant.register(with: engine)
        return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }
}
