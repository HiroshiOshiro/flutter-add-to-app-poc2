import Flutter
// GeneratedPluginRegistrant はFlutterではなく
// FlutterPluginRegistrant モジュールにある。
import FlutterPluginRegistrant
import UIKit

/// Flutterのエンジンを一元管理する唯一の場所。
///
/// 画面ごとにFlutterEngineを個別に生成すると1つあたり数十MBを消費するため、
/// 画面数が増えると成立しなくなる。`FlutterEngineGroup` から生成したエンジンは
/// スナップショット・GPUコンテキスト・フォントを共有するので、2つ目以降の
/// 増分はごくわずかで済む。
///
/// 「画面ごとに新しいエンジンを使う」設計を安価に成立させるのがこの仕組みの
/// 目的で、画面ごとに状態を持ち越したくないフロー画面と相性が良い。
/// タブのように長く生き続ける画面でエンジンを保持したい場合は、Phase 2 で
/// キャッシュを足す。
enum FlutterHost {

    private static let engineGroup = FlutterEngineGroup(
        name: "legacyapp_engine_group",
        project: nil
    )

    /// 指定したルートのFlutter画面を表示するViewControllerを作る。
    ///
    /// ネイティブ側が知っているのは「ルート名」だけで、その名前に対応する
    /// 画面がFlutter側のどのWidgetかは知らない。画面をFlutter化するときに
    /// ネイティブ側へコードを足さずに済むのはこのため。
    static func viewController(route: String) -> UIViewController {
        // entrypoint に nil を渡すと main() が使われる。Dart側の
        // エントリポイントは1つだけなので、指定するのは初期ルートのみ。
        let engine = engineGroup.makeEngine(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: route
        )

        // プラグインの登録はエンジンが実行された後でなければならない。
        // makeEngine(withEntrypoint:...) は生成と同時に実行するため、ここが正しい順序。
        GeneratedPluginRegistrant.register(with: engine)

        return FlutterScreenViewController(engine: engine)
    }
}
