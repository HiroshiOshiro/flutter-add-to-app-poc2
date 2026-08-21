package com.example.legacyapp.flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Flutter画面を表示する唯一のActivity。
 *
 * 画面ごとにActivityを作らないのが要点。どの画面を表示するかは
 * [FlutterHost.intentFor] が指定した初期ルートで決まるため、画面を
 * Flutter化してもこのクラスには手を入れない。
 */
class FlutterScreenActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // プラグインの登録はここで行われる。独自のチャンネルを登録するのは
        // その後（エンジンが実行された後）でなければならない。
        super.configureFlutterEngine(flutterEngine)
        NativeServices.attach(this, flutterEngine)
    }
}
