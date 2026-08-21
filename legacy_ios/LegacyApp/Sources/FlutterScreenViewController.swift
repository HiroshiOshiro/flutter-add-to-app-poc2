import Flutter
import UIKit

/// Flutter画面を表示する唯一のViewController。
///
/// 画面ごとにViewControllerを作らないのが要点。どの画面を表示するかは
/// `FlutterHost.viewController(route:)` が渡した初期ルートで決まるため、
/// 画面をFlutter化してもこのクラスには手を入れない。
final class FlutterScreenViewController: FlutterViewController {

    init(engine: FlutterEngine) {
        super.init(engine: engine, nibName: nil, bundle: nil)
        NativeServices.attach(to: engine, presenting: self)
    }

    // UIViewControllerの `init(coder:)` は非failableなので、failableとして
    // オーバーライドするとコンパイルエラーになる。
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Flutter側のScaffoldが自前でAppBarを描くため、ホストの
        // ナビゲーションバーをそのまま出すと二重に表示される。
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
