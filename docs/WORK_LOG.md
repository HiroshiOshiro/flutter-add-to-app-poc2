# 作業ログ

「最初から全面Flutter化を前提とする」構成で、既存ネイティブアプリを段階的に
移行していく作業の記録。設計判断とその理由、実際に起きた問題と対処を、
作業した順に残す。

一般化した手順は `MIGRATION_GUIDE.md` に分離する。こちらは本リポジトリ固有の
具体的な内容を書く。

## このリポジトリの位置づけ

先行する検証リポジトリ `flutter-add-to-app-poc` は、確認画面を1つFlutter化し、
その後にMusicタブをFlutter化する、という順で積み上げた。結果として動くものは
できたが、**画面を足すたびにDartのエントリポイントとネイティブ側の起動コードが
増える**構成になった。1〜2画面なら問題ないが、全画面をFlutter化する前提だと
途中で作り直しが必要になる。

本リポジトリでは、先行リポジトリの **Flutter導入直前のコミット `580a513`**
から分岐し、**最初から全面移行を前提とした構成**で同じ移行をやり直す。
第一歩は先行リポジトリと同じ「確認画面1つだけ」にして、同じ地点での構成の
違いが比較できるようにする。

### 段階

| | 内容 |
|---|---|
| Phase 0 | 土台（モジュール・単一エントリポイント・エンジン共有・チャンネル設計・フィーチャーフラグ） |
| Phase 1 | 確認画面のみをFlutter化（先行リポジトリと同じ地点） |
| Phase 2 | Musicタブ。**既存タブを置き換えず、Flutter版タブを追加**して既存SQLiteを共有できるか実地で確認する |
| Phase 3 | タブバー自体をFlutterへ（主従の逆転） |

## Phase 0-0: 分岐元の確認

`580a513`（お気に入りの保存先をSQLiteに変更）時点のコードだけを持つ新しい
リポジトリを作成した。Flutter関連のコミット・ファイルは含まれていない。

分岐直後にAndroid/iOSの両方をビルドして、移行前の状態が新しい場所でも動作
することを確認した。

**気づいた点: `local.properties` はコミットされない。** Androidの
`local.properties` はマシン固有のためgitignore対象であり、リポジトリを
clone しただけではAndroidビルドが
`SDK location not found` で失敗する。

```
sdk.dir=$HOME/Library/Android/sdk
```

を手で作る必要がある。Android Studioで開けば自動生成されるが、コマンド
ラインだけで作業する場合は最初に引っかかる。README に書く。

## Phase 0-1: Flutterモジュールの作成とDart側の土台

```bash
flutter create --template module --org com.example --project-name legacyapp_flutter legacyapp_flutter
```

### モジュール名

先行リポジトリでは最初のFlutter化対象が確認画面だったため `confirm_module`
という名前にしたが、Musicタブを足した時点で実態と合わなくなり、後からリネーム
することになった。**1つのホストアプリに組み込めるFlutterモジュールは1つだけ**
なので、モジュール名は機能ではなくホストアプリに紐づける。今回は最初から
`legacyapp_flutter` とした。

### ディレクトリ構成

[公式のアーキテクチャガイド](https://docs.flutter.dev/app-architecture/guide)
の構成に従う。

```
lib/
  main.dart                   唯一のエントリポイント + アプリシェル
  routing/
    routes.dart               ルート名の定義
    router.dart               Flutter化済み画面の登録表とルート解決
  ui/
    core/
      themes/                 共通テーマ
      ui/                     複数featureで使う共通Widget
    <feature>/
      view_models/            画面の状態とロジック
      widgets/                画面のWidget
  domain/
    models/                   UI層・データ層の両方が使うモデル
  data/
    repositories/             データの単一の情報源
    services/                 外部API・プラットフォーム呼び出しのラップ
  utils/                      ロギングなどの補助
```

ガイドの分類では**UI層はfeature単位、データ層は種類単位**で整理する。
Repository と Service は複数のfeatureから再利用されるため種類でまとめ、
View と ViewModel は1対1で対応するためfeatureでまとめる、という考え方。

先行リポジトリは `lib/domain` `lib/data` `lib/presentation` をトップレベルに
置き、UI層もfeatureで分けていなかった。画面が1〜2個なら見通しが良いが、
featureが増えると `presentation/` に無関係な画面が並んでいく。

**この構成には途中で切り替えた。** 最初はUI層もデータ層もfeature単位で
まとめる構成（`lib/features/<name>/{domain,data,presentation}`）で書いたが、
公式ガイドに合わせて上記へ作り直した。判断としては、独自の整理方針より
公式ガイドに乗せた方が、後から参加する開発者が既存の知識をそのまま使える
という理由が大きい。

**MethodChannelのラッパーはServiceに置く。** ガイドはServiceを「外部APIや
プラットフォーム呼び出しをラップし、状態を持たないクラス」と定義しており、
MethodChannelのラッパーはこれに正確に該当する。当初 `core/channels/` という
独自の置き場を作っていたが、`data/services/` に移して名前も
`NavigationService` / `LegacyStoreService` に揃えた。

**ViewModelはRiverpodの `Notifier` で実装する。** ガイドの例は
`ChangeNotifier` を使っているが、ガイド自体は状態管理ライブラリを限定して
いない。ViewModelの役割（Repositoryからデータを取得し、UIの状態として保持し、
コマンドを公開する）はそのままに、実装をRiverpodの `Notifier` にする。

### 設計判断

**1. エントリポイントは `main()` ひとつ。**
先行リポジトリは `main()` と `musicMain()` の2つを持ち、ネイティブ側は
画面ごとに別のエントリポイントを指定してエンジンを起動していた。この方式は
画面が増えるたびにネイティブ側の起動コードも増える。

今回は **どの画面を表示するかをネイティブから渡す初期ルートで決める**。
Dart側は `PlatformDispatcher.instance.defaultRouteName` で受け取る。画面を
Flutter化するときに触るのは `AppRoutes` へのルート名追加と登録表への1行だけで、
ネイティブ側には画面ごとのコードを足さない。

**2. 画面遷移の所有権はFlutter側に置く。**
先行リポジトリは確認画面の「完了画面へ遷移」をMethodChannelでネイティブに
依頼していた。確認画面1つだけをFlutter化するなら自然な設計だが、遷移先も
いずれFlutter化されるため、このブリッジは捨てコードになる。

今回はFlutterの `Navigator` が遷移を持ち、ネイティブへの依頼は**Flutterの
領域から出るときだけ**に限定する。Flutter化済みの画面同士の遷移はネイティブを
経由しないため、画面が増えてもネイティブ⇔Flutterの境界は増えない。

**3. MethodChannel（=Service）は画面単位ではなく機能単位で切る。**
先行リポジトリのチャンネル名は `com.example.legacyapp/confirm` で、画面名を
含んでいた。画面が増えればチャンネルとハンドラも増える。

今回は機能単位にした。

| チャンネル | 役割 | 移行完了時 |
|---|---|---|
| `…/navigation` | Flutterの領域から出る遷移をネイティブへ依頼（`NavigationService`） | 消える |
| `…/legacy_store` | ネイティブが保存済みのローカルデータを読む（`LegacyStoreService`） | 消える |

画面が増えてもチャンネルは増えず、**機能がFlutterへ移るたびに減っていく**。
これが全面移行では正しい方向になる。認証・共通ヘッダが必要になった場合は
`…/session` を足す想定だが、本アプリには認証がないため現時点では作らない
（使われない抽象を先に作らない）。

**4. 共通基盤は最初からDart側に置く。**
テーマ（`ui/core/themes`）・ロギング（`utils`）・APIクライアント
（`data/services`）をDartで実装した。既存の通信基盤を
ネイティブに温存してMethodChannelで呼ぶ作りは、そのブリッジを全画面が使う
ことになり捨てコードが最大化する。移行の初期は過剰投資に見えるが、3画面目
以降で回収できる。

**5. 未登録ルートを無言で無視しない。**
ネイティブ側のルート名とDart側の `AppRoutes` がずれると、何も表示されない
白画面になって原因が分かりにくい。`onGenerateRoute` のフォールバックで
「このルートに対応するFlutter画面が登録されていない」と画面上に出すようにした。

### つまずいた点: `use_null_aware_elements` の書き方

`flutter analyze` が

```
info • Use the null-aware marker '?' rather than a null check via an 'if'
     • lib/core/channels/navigation_channel.dart • use_null_aware_elements
```

を出した。`if (arguments != null) 'arguments': arguments,` をnull-aware
マーカーに書き換える際、最初に**キー側**に付けて

```
warning • The map entry key can't be null, so the null-aware operator '?'
        is unnecessary • invalid_null_aware_operator
```

になった。マーカーは値側に付ける。

```dart
// 誤り
?'arguments': arguments,
// 正しい
'arguments': ?arguments,
```

### 検証

- `flutter analyze` — 問題なし
- `flutter test` — 8件すべて通過
  - アプリシェル: 初期ルートに対応する画面が出ること、Flutter画面同士の遷移が
    ネイティブを経由せずに動くこと、未登録ルートでフォールバックが出ること
  - チャンネル: `openNative` / `close` / `readStrings` が期待した引数で
    ネイティブへ送られること、引数なしの場合に余計なキーを送らないこと、
    ネイティブの応答がnullのときに空として扱われること

この時点では登録済みの画面が0件のため、実機での確認はネイティブ側の土台
（Phase 0-2）と合わせて行う。

## Phase 0-2: Android側の土台

### Gradleの配線

`settings.gradle` で `include_flutter.groovy` を評価し、`app/build.gradle` に
`implementation project(':flutter')` を足す。ここで増えるサブプロジェクト名は
`:flutter` に固定されている。

**予見できた問題: リポジトリ集中管理との衝突。** 本アプリの
`settings.gradle` は `repositoriesMode` が `FAIL_ON_PROJECT_REPOS` になって
いた。Flutterのgradleプラグインはプロジェクトレベルで独自にリポジトリを
追加するため、この設定のままFlutterモジュールを組み込むとビルドが失敗する。
先行リポジトリで踏んだ問題なので、組み込みと同時に次の2点を先に対処した。

- `repositoriesMode` を `PREFER_SETTINGS` に緩和
- Flutterエンジン本体の配布先 `https://storage.googleapis.com/download.flutter.io`
  を `settings.gradle` 側のリポジトリに追加

**Kotlinの追加。** Flutter統合のために新規に書くコードはKotlinで書く。
ルートの `build.gradle` に kotlin-gradle-plugin を、`app/build.gradle` に
`kotlin-android` プラグインを追加した。既存のJavaと同一Gradleモジュール内で
共存でき、相互に呼び出せる。JavaとKotlinでターゲットが揃っていないと
`Inconsistent JVM-target compatibility detected` で失敗するため、
`kotlinOptions { jvmTarget = '1.8' }` を既存の `compileOptions` に合わせて
指定した（これも先行リポジトリで踏んでいる）。

### ネイティブ側のクラス構成

```
flutter/
  FlutterHost.kt            FlutterEngineGroupの保持とIntentの生成
  FlutterScreenActivity.kt  Flutter画面を表示する唯一のActivity
  NativeRouter.kt           論理的な画面名 -> ネイティブ実装かFlutter実装かの判断
  NativeServices.kt         機能単位のMethodChannelハンドラ
  FeatureFlags.kt           画面ごとのFlutter有効/無効
```

**Activityは画面ごとに作らない。** 先行リポジトリは `ConfirmFlutterActivity`
を作り、Musicタブを足すときに `MusicFlutterEngineHolder` を追加した。つまり
画面が増えるたびにネイティブ側のクラスが増えていた。

今回は `FlutterScreenActivity` ひとつで、どの画面を表示するかは
[FlutterHost.intentFor] が渡す初期ルートで決まる。**画面をFlutter化しても
このActivityには手を入れない。**

**エンジンは `FlutterEngineGroup` から生成する。** 画面ごとにFlutterEngineを
個別に生成すると1つあたり数十MBを消費するため、画面数が増えると成立しない。
EngineGroupから生成したエンジンはスナップショット・GPUコンテキスト・フォントを
共有するので、2つ目以降の増分はごくわずかで済む。

Flutterは `FlutterActivity.NewEngineInGroupIntentBuilder` を用意しており、
エンジンの生成・実行・破棄はこれに任せられる。先行リポジトリでは
`FlutterEngine` を手で生成していたため `FlutterLoader.ensureInitializationComplete()`
の呼び忘れやプラグイン登録の順序で複数回つまずいたが、今回はその層に
触っていない。

**フラグの判断は1箇所に集約する。** 呼び出し側が `FeatureFlags` を直接見る
作りにすると、画面をFlutter化するたびに分岐がアプリ中に散らばる。
`NativeRouter` が「確認画面へ行きたい」という要求を受けて、ネイティブ実装と
Flutter実装のどちらを開くかを決める。`MemoFragment` は
`new Intent(requireContext(), ConfirmActivity.class)` を直接作るのをやめ、
`NativeRouter.intentFor(context, Screen.CONFIRM)` を呼ぶだけになった。

**FlutterActivityのテーマ。** Flutter側の `Scaffold` が自前でAppBarを描くため、
ホストの ActionBar と二重に表示される。`Theme.MaterialComponents.Light.NoActionBar`
を親にした `FlutterTheme` を用意してManifestで割り当てた。

### 検証

エミュレータで両方の経路を確認した。

| フラグ | 結果 |
|---|---|
| OFF（既定） | 従来通りネイティブの確認画面が開く。**移行前の挙動が変わっていない** |
| ON | Flutter画面が開き、`No Flutter screen is registered for "/confirm"` が表示される |

フラグONで意図した通りの表示になったことで、次の経路が通っていることが
確認できた。

```
MemoFragment -> NativeRouter -> FeatureFlags(ON)
  -> FlutterHost（EngineGroupからエンジン生成・初期ルート "/confirm" を指定）
  -> FlutterScreenActivity -> Dart側 main() -> AppRouter
  -> 未登録ルートのフォールバック画面
```

Phase 1 で残っているのは **Dart側の登録表に1行足すこと**だけで、ネイティブ側の
コードは変更しない。これが本構成の狙い通りかどうかは Phase 1 で確認する。

**フラグの切り替え方（動作確認用）。** アプリを停止した状態で
SharedPreferences のファイルを直接置き換える。再ビルド不要でフラグの
切り替えが効くことも同時に確認できる。

```bash
adb shell am force-stop com.example.legacyapp
adb push feature_flags.xml /data/local/tmp/feature_flags.xml
adb shell run-as com.example.legacyapp \
  cp /data/local/tmp/feature_flags.xml shared_prefs/feature_flags.xml
```

`run-as` のシェル内で `mkdir -p shared_prefs && cp ...` のように複合コマンドを
書くと `mkdir: Needs 1 argument` になる。`run-as` は単一コマンドとして扱う。

## Phase 0-3: iOS側の土台

### CocoaPodsの配線

`Podfile` を新規作成し、Flutterモジュールの `.ios/Flutter/podhelper.rb` を
`load` して `install_all_flutter_pods` を呼ぶ。`post_install` に
`flutter_post_install(installer)` を書かないと `pod install` が
`Missing flutter_post_install(installer) in Podfile post_install block`
で失敗する。

XcodeGenでプロジェクトを生成しているため、順序を守る必要がある。

```
project.yml を変更 -> xcodegen generate -> pod install -> .xcworkspace でビルド
```

`xcodegen generate` はCocoaPodsが `.pbxproj` に注入したビルドフェーズを消して
しまうため、必ず `pod install` を後に実行する。ビルドは `.xcodeproj` ではなく
`.xcworkspace` に対して行う。

### Objective-CとSwiftの相互運用

Flutter統合のために新規に書くコードはSwiftにする。既存のObjective-Cと
双方向に参照するため、`project.yml` に3つの設定を足した。

| 設定 | 用途 |
|---|---|
| `SWIFT_VERSION` | Swiftを含むターゲットに必要 |
| `SWIFT_OBJC_BRIDGING_HEADER` | Swiftから既存のObjective-C型を参照する |
| `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` | Swiftファイルを1つでも追加する場合に有効化 |

逆向き（Objective-Cから新規のSwiftクラスを参照する）は、自動生成される
`LegacyApp-Swift.h` をimportするだけでよく、個別のヘッダーは不要。
`InputViewController.m` はこれをimportして `NativeRouter` を呼んでいる。

### ネイティブ側のクラス構成

Android側と1対1で対応させた。

```
FlutterHost.swift                FlutterEngineGroupの保持とViewControllerの生成
FlutterScreenViewController.swift  Flutter画面を表示する唯一のViewController
NativeRouter.swift               論理的な画面名 -> ネイティブ実装かFlutter実装かの判断
NativeServices.swift             機能単位のMethodChannelハンドラ
FeatureFlags.swift               画面ごとのFlutter有効/無効
```

`InputViewController.m` は
`[[ConfirmViewController alloc] init]` を直接作るのをやめ、
`[NativeRouter viewControllerFor:NativeRouter.screenConfirm]` を呼ぶだけに
なった。Android側の `MemoFragment` と同じ形。

### つまずいた点1: `FlutterEngineGroup.Options` はSwiftから使えない

`FlutterEngineGroup` にオプションを渡す形で書いたところ

```
error: type 'FlutterEngineGroup' has no member 'Options'
```

になった。ヘッダーを確認すると、オプション型は `FlutterEngineGroup` の
ネストした型ではなく `FlutterEngineGroupOptions` という独立したクラスで、
Swiftにもその名前で入ってくる。今回は初期ルートしか指定しないため、
オプションを使わない方のAPIにした。

```swift
let engine = engineGroup.makeEngine(
    withEntrypoint: nil,   // nil で main() が使われる
    libraryURI: nil,
    initialRoute: route
)
```

### つまずいた点2: `GeneratedPluginRegistrant` は別モジュール

```
error: cannot find 'GeneratedPluginRegistrant' in scope
```

`import Flutter` だけでは見つからない。`GeneratedPluginRegistrant` は
`FlutterPluginRegistrant` という別のPod／モジュールにあるため、
`import FlutterPluginRegistrant` が必要。

### つまずいた点3: 起動中のシミュレータが複数あると `booted` が別端末を指す

ビルドしたアプリを `xcrun simctl install booted` でインストールしたのに、
画面には**先行リポジトリのアプリ**が表示され続けた。原因はシミュレータが
3台起動していたことで、`booted` はそのうちの1台（画面に出していない端末）を
指していた。

```bash
xcrun simctl list devices booted   # 起動中の端末を確認する
```

インストール先とスクリーンショットを撮る端末が一致しているかは、UDIDを
明示して確かめるのが確実。ビルドしたバイナリのサイズ・タイムスタンプを
インストール先のものと突き合わせると、取り違えにすぐ気づける。

### ナビゲーションバーの二重表示

Flutter側の `Scaffold` が自前でAppBarを描くため、ホストの
`UINavigationController` のバーをそのまま出すと二重になる。
`FlutterScreenViewController` の `viewWillAppear` / `viewWillDisappear` で
バーの表示を切り替えている。Androidの `FlutterTheme`（NoActionBar）と
同じ問題への対処。

### 検証

シミュレータで両方の経路を確認した。

| フラグ | 結果 |
|---|---|
| OFF（既定） | 従来通りネイティブ（UIKit）の確認画面が開く。**移行前の挙動が変わっていない** |
| ON | Flutter画面が開き、`No Flutter screen is registered for "/confirm"` が表示される |

**フラグの切り替え方（動作確認用）。** iOSでは
`xcrun simctl spawn <udid> defaults write <bundle id> ...` はアプリの
コンテナには書き込まれない。コンテナ内のplistを直接作る。

```bash
xcrun simctl terminate <udid> com.example.legacyapp
C=$(xcrun simctl get_app_container <udid> com.example.legacyapp data)
/usr/libexec/PlistBuddy -c "Add :feature_flag.screen_confirm bool true" \
  "$C/Library/Preferences/com.example.legacyapp.plist"
xcrun simctl launch <udid> com.example.legacyapp
```

## Phase 0 のまとめ

Android・iOSの両方で、次の経路が通っている。

```
ネイティブの画面 -> NativeRouter -> FeatureFlags
  -> FlutterHost（EngineGroupからエンジン生成・初期ルートを指定）
  -> Flutter表示用の共通コンテナ -> Dart側 main() -> AppRouter
  -> （まだ画面が未登録なのでフォールバック）
```

Flutter化した画面は0件だが、**土台はすべて揃っている**。Phase 1 で行うのは
Dart側にConfirm画面を実装して登録表に1行足すことだけで、**ネイティブ側の
コードには手を入れない**見込み。それが実際に成立するかどうかが、この構成が
狙い通りかを判定する基準になる。
