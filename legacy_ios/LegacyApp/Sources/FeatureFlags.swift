import Foundation

/// 画面ごとに「Flutter版を使うか、ネイティブ実装のままにするか」を切り替えるフラグ。
///
/// 段階移行では、Flutter化した画面に問題が見つかったときにリリースを待たずに
/// ネイティブ実装へ戻せる退路が必要になる。1画面目をFlutter化する時点で
/// この仕組みを入れておくのが要点で、画面が増えてから後付けするのは難しい。
///
/// 本PoCでは既定値をコード内に持ちつつ、UserDefaultsで上書きできるようにして
/// いる。実運用ではリモート設定に置き換わる部分。
@objc final class FeatureFlags: NSObject {

    /// 入力内容の確認画面。
    @objc static let screenConfirm = "screen_confirm"

    /// 各画面の既定値。Flutter化が完了して安定したものからtrueにしていく。
    /// Phase 0 の時点ではFlutter側に画面が1つも無いため、すべてfalse。
    private static let defaults: [String: Bool] = [
        screenConfirm: false
    ]

    @objc static func useFlutter(_ screen: String) -> Bool {
        if let override = UserDefaults.standard.object(forKey: flagKey(screen)) as? Bool {
            return override
        }
        return defaults[screen] ?? false
    }

    /// 動作確認用。実運用ではリモート設定から降ってくる想定。
    @objc static func override(_ screen: String, useFlutter: Bool) {
        UserDefaults.standard.set(useFlutter, forKey: flagKey(screen))
    }

    /// 既存の下書きキーと衝突しないよう、フラグ用の接頭辞を付ける。
    private static func flagKey(_ screen: String) -> String {
        "feature_flag.\(screen)"
    }
}
