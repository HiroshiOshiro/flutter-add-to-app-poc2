# MIGRATION_GUIDE.md 追試検証の操作ログ

`docs/MIGRATION_GUIDE.md` の手順が「書いてある通りにやって本当に動くか」を、
Flutter未導入の状態（コミット `580a513`）から追試した記録。

実行した操作と、返ってきた結果をその場で逐次記録する。設計判断やつまずきの
考察は `WORK_LOG.md` 側に書く。

- ブランチ: `verify/migration-guide`（`580a513` から作成）
- ガイドの参照方法: このブランチにはガイドが存在しないため
  `git show main:docs/MIGRATION_GUIDE.md` で参照する
- Android組み込み方式: source module
- iOS組み込み方式: Swift Package Manager

---

## Step 0: 環境の用意

### Flutter SDK を 3.47.1 へ

ガイドが推奨するiOSのSPM手順は Flutter 3.44 以降が必要。作業前の 3.41.2 には
`flutter build swift-package` が存在しなかったため、SDKを更新した。

```
$ git -C /Users/hiroshi/Documents/flutter fetch --tags origin
$ git -C /Users/hiroshi/Documents/flutter checkout 3.47.1
$ flutter --version
Flutter 3.47.1 • channel [user-branch] • https://github.com/flutter/flutter.git
Tools • Dart 3.13.1 • DevTools 2.60.0

$ flutter build --help | grep swift-package
  swift-package     Produces Swift packages and scripts for a Flutter project
                    and its plugins for integration into existing, native
                    non-Flutter iOS and macOS Xcode projects.
```

**判定: ガイドに不足あり。** ガイドはiOSの節で「Flutter 3.44以降」と書いて
いるが、**前提条件としては前の方に書かれていない**。iOSでSPMを使うなら
Flutterのバージョン確認が最初の作業になるため、冒頭の前提に移すべき。

> なお `git checkout <tag>` によるバージョン固定はチャンネルが
> `[user-branch]` になり、以降 `flutter upgrade` が使えなくなる。

### 検証用ブランチ

```
$ git checkout -b verify/migration-guide 580a513
```

`main` で生成されていた `legacyapp_flutter/`（`.android/` `.ios/` など
gitignore対象のため checkout で消えない）と `legacy_ios/Pods/`、
`legacy_ios/LegacyApp.xcworkspace` が残っていたため削除し、Flutter未導入の
状態にした。

**判定: ガイドに不足あり。** 「一度組み込んだものを外す・やり直す」手順が
ガイドに無い。gitignore対象の生成物は `git checkout` では消えないため、
検証や切り戻しのときに古い状態が残る。

### ベースラインの確認

```
$ (legacy_android) ./gradlew assembleDebug
BUILD SUCCESSFUL in 11s

$ (legacy_ios) xcodegen generate && xcodebuild ... build
** BUILD SUCCEEDED **
```

Flutter組み込み前の状態で両OSともビルドできることを先に確認した。

---

## Step 1: ガイド「3. ステップ1: Flutterモジュールを作る」

### ガイドの記述

```bash
flutter create -t module --org com.example flutter_module
```

> 1アプリに1モジュールしか組み込めないため、**このモジュールは将来Flutter化する
> すべての画面の置き場**になる。（中略）ホストアプリに紐づく名前にしておく。

> `pubspec.yaml` の `module.androidPackage` は、**ホストアプリのパッケージ名と
> 異なる**必要がある。同じにするとDexのマージで衝突する。

### 実行したコマンド

ガイドの命名方針に従い、モジュール名をホストアプリに紐づけた。

```
$ flutter create -t module --org com.example legacyapp_flutter
Wrote 12 files.
All done!
```

### 結果

```
$ grep -A4 "^  module:" legacyapp_flutter/pubspec.yaml
  module:
    androidX: true
    androidPackage: com.example.legacyapp_flutter
    iosBundleIdentifier: com.example.legacyappFlutter

$ grep "applicationId" legacy_android/app/build.gradle
        applicationId "com.example.legacyapp"
```

`.android/` と `.ios/` も生成された。

### 判定

**おおむねOK。ただし2点の不足あり。**

1. **`androidPackage` は既定で衝突しない。** 生成された
   `com.example.legacyapp_flutter` はホストアプリの `com.example.legacyapp` と
   自動的に異なる。ガイドの書き方だと「自分で直す必要がある作業」に読めるが、
   実際に問題になるのはモジュール名をホストアプリ名と同じにした場合だけ。
   確認事項であって作業ではない、と分かるように直す。

2. **モジュールをどこに置くかが書かれていない。** ガイドの後続の
   スニペットは `settingsDir.parentFile + "/flutter_module/..."` や
   `'../flutter_module'` のように**ホストアプリと兄弟ディレクトリである前提**で
   書かれているが、その前提が明示されていない。公式ドキュメントは
   ディレクトリ構成を図示している。ガイドにも配置を明記すべき。

---

## Step 2: ガイド「4. ステップ2-A: Androidへ組み込む」（source module）

### ガイドの記述

> - **Java 17 以上**（ホストアプリの `compileOptions` を確認する）
> - Gradle 7 以上（リポジトリの集中管理を使うため）

> **`FAIL_ON_PROJECT_REPOS` にしているプロジェクトは、この設定のまま組み込むと
> ビルドが失敗する。**

```groovy
// settings.gradle
include(":app")
setBinding(new Binding([gradle: this]))
def filePath = settingsDir.parentFile.toString() + "/flutter_module/.android/include_flutter.groovy"
apply from: filePath
```

### 2-1. `FAIL_ON_PROJECT_REPOS` のまま組み込む（検証点C）

ガイドの警告が実際に起きるか確認するため、**リポジトリ設定を先に直さずに**
source module のスニペットだけを貼ってビルドした。

```
$ ./gradlew assembleDebug

FAILURE: Build failed with an exception.
* Where:
Build file '.../legacyapp_flutter/.android/Flutter/build.gradle' line: 5
* What went wrong:
An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
   > Build was configured to prefer settings repositories over project repositories
     but repository 'maven' was added by plugin 'dev.flutter.flutter-gradle-plugin'
```

**判定: ガイドの記述は正しい。** ただしエラー文が載っていないため、
遭遇したときにガイドの該当箇所と結びつけにくい。**エラー文を追記すべき。**

なお、ガイドの settings.gradle スニペット（`apply from:` +
`settingsDir.parentFile`）は**そのまま動いた**（検証点B: OK）。

### 2-2. ガイドの対処を適用

```groovy
dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.PREFER_SETTINGS
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}
```

先ほどのエラーは消え、同じ文言が**警告として3行出るだけ**になった。

### 2-3. Gradle のバージョン要求（ガイドに無い）

```
* What went wrong:
   > Error: Your project's Gradle version (8.9.0) is lower than Flutter's
     minimum supported version of 8.14.0. Please upgrade your Gradle version.
```

**判定: ガイドが誤り。** ガイドは「Gradle 7 以上」と書いているが、
**Flutter 3.47.1 が要求するのは Gradle 8.14 以上**だった。
`gradle-wrapper.properties` を `8.14.3` に更新して解消。

### 2-4. Android Gradle Plugin のバージョン要求（ガイドに無い）

```
* What went wrong:
   > Error: Your project's Android Gradle Plugin version (Android Gradle Plugin
     version 8.7.0) is lower than Flutter's minimum supported version of
     Android Gradle Plugin version 8.11.1.
```

**判定: ガイドに不足あり。** AGPのバージョン要求が**まったく書かれていない**。
`8.7.0` → `8.11.1` に更新して解消。

### 2-5. ビルド成功

```
$ ./gradlew assembleDebug
BUILD SUCCESSFUL in 1m 4s
```

### 2-6. Java 17 の要否（検証点A）

**`compileOptions` を `1.8` のままにしてビルドが成功した。**

```
$ grep -A3 compileOptions app/build.gradle
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

$ ./gradlew -version
Gradle 8.14.3
Launcher JVM:  21.0.10 (JetBrains s.r.o.)
```

**判定: ガイドが誤解を招く。** ガイド（および公式ドキュメント）は
「Java 17 以上」の説明として `compileOptions` のスニペットを示しているが、
実際に満たす必要があったのは **Gradle を動かす JDK のバージョン**（ここでは
Android Studio 同梱の JDK 21）だった。ホストアプリの `compileOptions` は
`1.8` のままで通る。両者を区別して書き直す必要がある。

### 2-7. abiFilters（検証点D）

未設定のままビルド・インストール・実行できた。**判定: 「推奨」の位置づけは
妥当**だが、必須ではないことと、何のために絞るのか（Flutterが対応しないABIを
ホストアプリがサポートしている場合にAPKサイズと実行時の問題を避けるため）を
明示した方がよい。

### Step 2 のまとめ

**ガイドに従うだけでは進めなかった。** 不足していたのは次の3点。

| 項目 | ガイドの記述 | 実際 |
|---|---|---|
| Gradle | 「7 以上」 | **8.14 以上**（Flutter 3.47.1） |
| Android Gradle Plugin | 記載なし | **8.11.1 以上** |
| Java 17 | `compileOptions` の話として記載 | **Gradleを動かすJDK**の話。`compileOptions` は 1.8 で可 |

いずれもエラーメッセージが親切で、読めば対処できる。だが「ガイドの前提条件を
満たしているつもりで着手したのに、3回ビルドが失敗する」体験になるため、
**バージョン要求はFlutter SDKのバージョンに紐づくことを明記し、確認手順を
先頭に置くべき**。

---

## Step 3: ガイド「6. ステップ3: Flutter画面を表示する」（Android）

### 3-1. Manifestスニペットをそのまま貼る

ガイドのスニペットを一字一句そのまま貼った。

```xml
<activity
  android:name="io.flutter.embedding.android.FlutterActivity"
  android:theme="@style/LaunchTheme"
  ... />
```

```
$ ./gradlew assembleDebug
ERROR: .../AndroidManifest.xml:33:9-39:13: AAPT: error: resource
style/LaunchTheme (aka com.example.legacyapp:style/LaunchTheme) not found.
```

**判定: ガイドが誤り。** `@style/LaunchTheme` は**Flutterが新規アプリを作った
ときに生成するテーマ**であり、既存のネイティブアプリには存在しない。
add-to-app のガイドとして、このスニペットをそのまま貼れば必ず失敗する。
テーマを自分で用意する必要があることと、その定義を載せるべき。

ホストアプリ既存の `@style/AppTheme` に差し替えて解消。

### 3-2. FlutterEngineGroup の起動コードが無い

ガイドは

> **`FlutterEngineGroup` を既定にしてよい。**

と書いているが、**Androidの起動コードとして載っているのは「新規エンジン」と
「キャッシュエンジン」の2つだけで、EngineGroup のスニペットが無い。**
公式APIを自分で調べて書く必要があった。

```java
FlutterEngineGroup group = new FlutterEngineGroup(requireContext());
FlutterEngine engine = group.createAndRunEngine(
        requireContext(),
        DartExecutor.DartEntrypoint.createDefault(),
        "/confirm");
FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, engine);
return FlutterActivity.withCachedEngine(FLUTTER_ENGINE_ID).build(requireContext());
```

**判定: ガイドに不足あり。** 推奨している方式のコードが載っていないのは
致命的。上記スニペットを追加すべき。

なお、EngineGroupから作ったエンジンは `FlutterEngineCache` に入れて
`withCachedEngine` で起動する、という**2つの仕組みの組み合わせ**になる点も
ガイドからは読み取れない。

### 3-3. スニペットがKotlinのみ

ガイドのAndroid側スニペットはすべてKotlinだが、**ホストアプリはJava**。
今回はJavaに書き換えて対応した。ガイドはKotlinを推奨しているものの、
Android統合の節にKotlinプラグインを有効化する手順が無いため、Kotlinで書くには
読者が自分でGradleを設定する必要がある。

**判定: ガイドに不足あり。** Kotlinで書くなら有効化手順を、書かないなら
Javaのスニペットも載せるべき。

### 3-4. 初期ルートの分割（検証点E）

ガイドの対処（`onGenerateInitialRoutes`）を**意図的に入れずに**実装して確認。

| 操作 | 結果 |
|---|---|
| Flutter画面を開く | `route: /confirm` が表示される。**AppBarに戻る矢印が出る** |
| 戻る操作 | ネイティブに戻らず `route: /` が表示される |

**判定: ガイドの記述は正しい。再現した。**

ただしガイドに書かれていない症状が1つある。**画面スタックが2つになるため、
Flutter側のAppBarに意図しない戻る矢印が表示される。** 戻る操作をする前に
気づける手がかりなので、ガイドに追記する価値がある。

対処を適用した結果:

| 操作 | 結果 |
|---|---|
| Flutter画面を開く | `route: /confirm`。**戻る矢印は出ない** |
| 戻る操作 | `MainActivity`（ネイティブ）に戻る |

### 3-5. AppBarの二重表示（検証点F）

**再現しなかった。** 2種類のテーマで試した。

| Flutter画面に当てたテーマ | 結果 |
|---|---|
| `Theme.MaterialComponents.Light.DarkActionBar`（AppCompat系） | 二重表示なし |
| `@android:style/Theme.Material.Light.DarkActionBar`（framework系） | 二重表示なし |

**判定: ガイドが誤り、または条件が不足。** `FlutterActivity` を使う限り、
ActionBar付きのテーマを当てても二重表示は起きなかった。ガイドの警告は
`FlutterFragment` をActionBarを描くActivityに埋め込む場合の話である可能性が
高い（今回は未検証）。**`FlutterActivity` の話として書くのは誤りなので、
条件を限定するか削除する。**

### 3-6. 到達点

```
--- Flutter画面 ---
  ACTIVITY com.example.legacyapp/io.flutter.embedding.android.FlutterActivity
--- 戻る操作の後 ---
  ACTIVITY com.example.legacyapp/.MainActivity
```

ネイティブ画面のボタンからFlutter画面が開き、初期ルートが渡り、戻る操作で
ネイティブに戻るところまで到達した。

### 3-7. 作業中に踏んだ罠（ガイドの範囲外だが記録）

**`adb install -r` が `INSTALL_FAILED_INSUFFICIENT_STORAGE` で失敗する。**
FlutterのDebug APKは1.4GBあり、上書きインストールに失敗する。エラーは
`-r` を付けていると見落としやすく、**古いAPKのまま動作確認して「修正が
効いていない」と誤判断しかけた**（今回2回発生）。

```
adb: failed to install app-debug.apk:
  Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE: Failed to override installation location]
```

`adb uninstall` してから `adb install` すれば通る。READMEの実行手順に注記を
入れる。

### Step 3 のまとめ

| 検証点 | 結果 |
|---|---|
| Manifestスニペット | **ガイドが誤り**（存在しないテーマを参照） |
| EngineGroup の起動コード | **ガイドに不足**（推奨方式のコードが無い） |
| スニペットの言語 | **ガイドに不足**（Kotlinのみ／有効化手順が無い） |
| 初期ルートの分割（E） | **ガイドは正しい**。症状（戻る矢印）を追記すべき |
| AppBarの二重表示（F） | **ガイドが誤り**。`FlutterActivity` では再現しない |
