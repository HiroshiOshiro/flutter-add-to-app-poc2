package com.example.legacyapp.flutter

import android.content.Context

/**
 * 画面ごとに「Flutter版を使うか、ネイティブ実装のままにするか」を切り替えるフラグ。
 *
 * 段階移行では、Flutter化した画面に問題が見つかったときにリリースを待たずに
 * ネイティブ実装へ戻せる退路が必要になる。1画面目をFlutter化する時点で
 * この仕組みを入れておくのが要点で、画面が増えてから後付けするのは難しい。
 *
 * 本PoCでは既定値をコード内に持ちつつ、SharedPreferencesで上書きできる
 * ようにしている。実運用ではリモート設定に置き換わる部分。
 */
object FeatureFlags {

    private const val PREFS_NAME = "feature_flags"

    /** 入力内容の確認画面。 */
    const val SCREEN_CONFIRM = "screen_confirm"

    /**
     * 各画面の既定値。Flutter化が完了して安定したものからtrueにしていく。
     * Phase 0 の時点ではFlutter側に画面が1つも無いため、すべてfalse。
     */
    private val defaults = mapOf(
        SCREEN_CONFIRM to false,
    )

    fun useFlutter(context: Context, screen: String): Boolean {
        val default = defaults[screen] ?: false
        return context.applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(screen, default)
    }

    /** 動作確認用。実運用ではリモート設定から降ってくる想定。 */
    fun override(context: Context, screen: String, useFlutter: Boolean) {
        context.applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(screen, useFlutter)
            .apply()
    }
}
