package com.example.legacyapp.flutter

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter側の Service に対応するネイティブ側のハンドラ。
 *
 * チャンネルは画面単位ではなく機能単位で切る。画面ごとにチャンネルを
 * 用意すると画面数だけハンドラが増えるが、機能単位なら画面が増えても
 * ハンドラは増えず、機能がFlutterへ移るたびに減っていく。
 */
object NativeServices {

    private const val CHANNEL_NAVIGATION = "com.example.legacyapp/navigation"
    private const val CHANNEL_LEGACY_STORE = "com.example.legacyapp/legacy_store"

    /** 移行前のネイティブコードが下書きを保存しているSharedPreferences。 */
    private const val LEGACY_PREFS_NAME = "legacy_app_prefs"

    fun attach(activity: Activity, engine: FlutterEngine) {
        attachNavigation(activity, engine)
        attachLegacyStore(activity.applicationContext, engine)
    }

    /** Flutterの領域から出る遷移をネイティブが引き受ける。 */
    private fun attachNavigation(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAVIGATION)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNative" -> {
                        val screen = call.argument<String>("route")
                        if (screen == null) {
                            result.error("invalid_argument", "route is required", null)
                            return@setMethodCallHandler
                        }
                        val intent = NativeRouter.intentFor(activity, screen)
                        if (intent == null) {
                            result.error("unknown_route", "No native screen for $screen", null)
                            return@setMethodCallHandler
                        }
                        activity.startActivity(intent)
                        activity.finish()
                        result.success(null)
                    }

                    "close" -> {
                        activity.finish()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 移行前のネイティブコードが保存したローカルデータを読ませる。
     *
     * Flutterのキーバリューストア用プラグインは既定ではキーにプレフィックスを
     * 付け、保存先ファイルもFlutter専用のものになるため、ここにある既存の値は
     * 見えない。プレフィックスを外して直接読むこともできるが、そうすると同じ
     * データを両側から読み書きできてしまう。所有者はネイティブのままにして、
     * 読み出しだけをこのチャンネルで提供する。
     */
    private fun attachLegacyStore(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_LEGACY_STORE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readStrings" -> {
                        val keys = call.argument<List<String>>("keys").orEmpty()
                        val prefs = context.getSharedPreferences(
                            LEGACY_PREFS_NAME,
                            Context.MODE_PRIVATE,
                        )
                        val values = mutableMapOf<String, String>()
                        for (key in keys) {
                            prefs.getString(key, null)?.let { values[key] = it }
                        }
                        result.success(values)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
