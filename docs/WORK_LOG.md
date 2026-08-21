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
