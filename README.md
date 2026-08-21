# flutter-add-to-app-poc2

既存のネイティブアプリ（iOS: Objective-C / Android: Java、いずれも旧
アーキテクチャ）を、**最初から全面Flutter化を前提とした構成**で段階的に
移行していく検証用リポジトリ。

先行リポジトリ [flutter-add-to-app-poc](https://github.com/HiroshiOshiro/flutter-add-to-app-poc)
の **Flutter導入直前のコミット `580a513`** から分岐している。第一歩は先行
リポジトリと同じ「確認画面1つだけをFlutter化」にしてあり、同じ地点での構成の
違いを比較できる。

- `legacy_android/` — 移行前を模したAndroidアプリ（Java）
- `legacy_ios/` — 移行前を模したiOSアプリ（Objective-C）
- `legacyapp_flutter/` — Flutterモジュール（[公式アーキテクチャガイド](https://docs.flutter.dev/app-architecture/guide)の構成）
- `docs/MIGRATION_GUIDE.md` — add-to-app の導入手順（一般化した内容）
- `docs/MIGRATION_GUIDE_OLD.md` — 上記の旧版
- `docs/WORK_LOG.md` — 作業ログ。設計判断の理由とつまずいた点
- `docs/GUIDE_VERIFICATION_LOG.md` — 導入ガイドをFlutter未導入の状態から
  追試した記録（ガイドのどこが誤り・不足だったか）

## 現在の状態（Phase 0 完了）

土台のみが揃っており、**Flutter化した画面はまだ0件**。フィーチャーフラグを
ONにするとFlutterは起動するが、ルートに対応する画面が未登録のため
`No Flutter screen is registered for "/confirm"` が表示される。これが
現時点での正しい動作。

| Phase | 内容 | 状態 |
|---|---|---|
| 0 | 土台（単一エントリポイント・エンジン共有・チャンネル設計・フィーチャーフラグ） | 完了 |
| 1 | 確認画面のみをFlutter化 | 未着手 |
| 2 | Music。既存タブを置き換えずFlutter版タブを追加し、既存SQLiteを共有できるか確認 | 未着手 |
| 3 | タブバー自体をFlutterへ | 未着手 |

## 前提環境

- Flutter SDK（`legacyapp_flutter/.metadata` に記録されているものと同じ
  リビジョン・チャンネルを推奨）
- Android: Android Studio（JDK同梱）、Android SDK、Androidエミュレータ
- iOS: Xcode、CocoaPods、[XcodeGen](https://github.com/yonaskolb/XcodeGen)
- `flutter` コマンドがPATHで使えること（`flutter doctor` で確認）

## 共通の準備（初回のみ）

Flutterモジュールの依存を取得する。この処理が `legacyapp_flutter/.android/`
と `.ios/` を生成し、ホストアプリ側はそこにあるファイルを参照するため、
**Android・iOSどちらをビルドする場合でも先に実行する必要がある**。

```bash
cd legacyapp_flutter
flutter pub get
```

## Android（legacy_android）を実行する

**Android SDKの場所を指定する。** 指定が無いとビルドが
`SDK location not found` で失敗する。方法は2つあり、**環境変数を推奨**する。

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
```

もう一方は `local.properties` に書く方法。このファイルは絶対パスを含む
マシン固有の設定であり、リポジトリには含まれない（gitignore対象）。
Android Studioでプロジェクトを開くと自動生成される。Gradleは生成しないため、
コマンドラインだけで作業する場合は環境変数を使うか、手で作る。

```bash
echo "sdk.dir=$HOME/Library/Android/sdk" > legacy_android/local.properties
```

Android Studioで `legacy_android` を開く場合は、エミュレータ/実機を選んで
Runするだけでよい。

コマンドラインでビルドする場合:

```bash
cd legacy_android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew assembleDebug
```

生成されたAPKをインストールして起動する（`legacy_android` にいる状態で）:

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.example.legacyapp/.MainActivity
```

## iOS（legacy_ios）を実行する

Xcodeプロジェクトを生成し、CocoaPodsで依存を解決する。

```bash
cd legacy_ios
xcodegen generate
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8   # 環境によっては pod install に必要
pod install
```

**`LegacyApp.xcworkspace` を開く。** `.xcodeproj` を直接開くとCocoaPods経由の
Flutter依存が解決されずビルドエラーになる。

```bash
open legacy_ios/LegacyApp.xcworkspace
```

Xcode上でシミュレータ/実機を選んでRunする。

`project.yml` や `LegacyApp/Sources` 配下にファイルを追加・削除した場合は、
**`xcodegen generate` → `pod install` → ビルド** の順序を毎回守ること。
`xcodegen generate` はCocoaPodsが `.pbxproj` に注入したビルドフェーズを消す
ため、`pod install` を後に実行する必要がある。

コマンドラインでビルドする場合:

```bash
cd legacy_ios
xcodebuild -workspace LegacyApp.xcworkspace -scheme LegacyApp \
  -sdk iphonesimulator -configuration Debug \
  -destination "generic/platform=iOS Simulator" build
```

## Flutterモジュール単体で確認する

```bash
cd legacyapp_flutter
flutter pub get
flutter analyze
flutter test
```

ホストアプリに組み込まずにモジュール単体をビルドすることもできる。
モジュール付属の `.android/` にあるラッパーアプリがビルドされるため、
Dartコードとビルドパスの健全性だけを先に確認したいときに使える。

```bash
cd legacyapp_flutter
flutter build apk --debug
```

## 一連の操作フロー

「メモ」タブの入力画面で Name / Email / Message を入力して「次へ」を押すと
確認画面へ進む。確認画面が**ネイティブ実装かFlutter実装か**は、後述の
フィーチャーフラグで決まる。

「Music」タブは iTunes Search API を使った楽曲検索・お気に入り登録
（ローカルSQLite保存）で、現時点では全てネイティブ実装。

## デバッグする

アプリを起動するのはネイティブのIDE側なので、`flutter run` は使えない。
アプリを起動してFlutter画面を表示した状態で `flutter attach` する。
ホットリロード・ホットリスタート・DevToolsがそのまま使える。

```bash
cd legacyapp_flutter
flutter attach -d <device-id>      # flutter devices で確認
```

対話操作なしでホットリロードしたい場合は `--pid-file` を使う。

```bash
flutter attach -d <device-id> --pid-file=/tmp/flutter.pid
kill -SIGUSR1 $(cat /tmp/flutter.pid)   # ホットリロード
kill -SIGUSR2 $(cat /tmp/flutter.pid)   # ホットリスタート
```

デバッグ対象によって使う道具が変わる。

| 対象 | 使うもの |
|---|---|
| Dartのコード | `flutter attach` + DevTools、またはIDEのFlutterデバッガをアタッチ |
| ネイティブのコード | Android Studio / Xcode のデバッガ |
| 境界（MethodChannel） | 両側にログを入れる。チャンネル名・メソッド名・引数の型のいずれかが食い違うと無言で失敗する |
| どちらの層の問題か | フィーチャーフラグでネイティブ実装に戻し、再現するか確認する |

**ビルドが端末に反映されているか怪しいとき**は、画面に出る一意な文字列を
一時的に仕込んで確認するのが確実。APK内のシンボルを `strings` で探す方法は、
Flutterフレームワーク側に同名のものがあると判定にならない。

## フィーチャーフラグを切り替える

Flutter化した画面に問題があったときにリリースを待たずネイティブ実装へ戻せる
よう、画面ごとにフラグを持たせている。既定値はコード内
（`FeatureFlags`）にあり、実行時に上書きできる。

**再ビルドは不要**で、動作確認にはこちらを使う。

### Android

アプリを停止した状態でSharedPreferencesのファイルを置き換える。
`shared_prefs/` はアプリの初回起動時に作られるため、**一度アプリを起動して
から**実行すること。

```bash
cat > /tmp/feature_flags.xml <<'XML'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map><boolean name="screen_confirm" value="true" /></map>
XML

adb shell am force-stop com.example.legacyapp
adb push /tmp/feature_flags.xml /data/local/tmp/feature_flags.xml
adb shell run-as com.example.legacyapp cp /data/local/tmp/feature_flags.xml shared_prefs/feature_flags.xml
adb shell am start -n com.example.legacyapp/.MainActivity
```

`run-as` は単一コマンドとして扱われるため、`mkdir -p ... && cp ...` のように
複合コマンドを書くと失敗する。

### iOS

`xcrun simctl spawn ... defaults write` はアプリのコンテナには書き込まれない
ため、コンテナ内のplistを直接編集する。

```bash
UDID=<対象シミュレータのUDID>   # xcrun simctl list devices booted で確認

xcrun simctl terminate $UDID com.example.legacyapp
C=$(xcrun simctl get_app_container $UDID com.example.legacyapp data)
/usr/libexec/PlistBuddy -c "Add :feature_flag.screen_confirm bool true" \
  "$C/Library/Preferences/com.example.legacyapp.plist"
xcrun simctl launch $UDID com.example.legacyapp
```

**シミュレータが複数起動している場合は `booted` を使わない。** `booted` は
画面に出していない端末を指すことがあり、インストールしたつもりのアプリが
反映されていないように見える。`xcrun simctl list devices booted` で確認し、
UDIDを明示する。

戻すときは `value="false"` にするか、フラグのファイル／キーを削除する。
