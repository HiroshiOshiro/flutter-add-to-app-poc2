package com.example.legacyapp.flutter

import android.content.Context
import android.content.Intent
import com.example.legacyapp.CompleteActivity
import com.example.legacyapp.ConfirmActivity

/**
 * 論理的な画面名から、実際に開くべき画面を決める。
 *
 * ネイティブ側もFlutter側も「確認画面へ行きたい」としか言わず、それが
 * Flutter実装なのかネイティブ実装なのかは[FeatureFlags]を見てここが決める。
 * 呼び出し側がフラグを直接見る作りにすると、Flutter化するたびに分岐が
 * アプリ中に散らばるため、判断を1箇所に集約する。
 */
object NativeRouter {

    /** ネイティブ側・Flutter側で共有する論理的な画面名。 */
    object Screen {
        const val CONFIRM = "confirm"
        const val COMPLETE = "complete"
    }

    /** Flutter側のルート名。Dartの `AppRoutes` と対応させる。 */
    private val flutterRoutes = mapOf(
        Screen.CONFIRM to "/confirm",
    )

    fun intentFor(context: Context, screen: String): Intent? {
        val flutterRoute = flutterRoutes[screen]
        if (flutterRoute != null && FeatureFlags.useFlutter(context, screenFlag(screen))) {
            return FlutterHost.intentFor(context, flutterRoute)
        }
        return nativeIntentFor(context, screen)
    }

    private fun screenFlag(screen: String): String = when (screen) {
        Screen.CONFIRM -> FeatureFlags.SCREEN_CONFIRM
        else -> screen
    }

    /** まだFlutter化していない、あるいはフラグで無効化されている画面。 */
    private fun nativeIntentFor(context: Context, screen: String): Intent? = when (screen) {
        Screen.CONFIRM -> Intent(context, ConfirmActivity::class.java)
        Screen.COMPLETE -> Intent(context, CompleteActivity::class.java)
        else -> null
    }
}
