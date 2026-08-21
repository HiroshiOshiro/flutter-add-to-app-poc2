package com.example.legacyapp.flutter

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineGroupCache

/**
 * Flutterのエンジンを一元管理する唯一の場所。
 *
 * 画面ごとにFlutterEngineを個別に生成すると1つあたり数十MBを消費するため、
 * 画面数が増えると成立しなくなる。[FlutterEngineGroup] から生成した
 * エンジンはスナップショット・GPUコンテキスト・フォントを共有するので、
 * 2つ目以降の増分はごくわずかで済む。
 *
 * 「画面ごとに新しいエンジンを使う」設計を安価に成立させるのがこの仕組みの
 * 目的で、画面ごとに状態を持ち越したくないフロー画面と相性が良い。
 * タブのように長く生き続ける画面でエンジンを保持したい場合は、Phase 2 で
 * キャッシュを足す。
 */
object FlutterHost {

    private const val ENGINE_GROUP_ID = "legacyapp_engine_group"

    /** アプリ起動時に1度だけ呼ぶ。 */
    fun initialize(context: Context) {
        val cache = FlutterEngineGroupCache.getInstance()
        if (cache.get(ENGINE_GROUP_ID) == null) {
            cache.put(ENGINE_GROUP_ID, FlutterEngineGroup(context.applicationContext))
        }
    }

    /**
     * 指定したルートのFlutter画面を開くIntentを作る。
     *
     * ネイティブ側が知っているのは「ルート名」だけで、その名前に対応する
     * 画面がFlutter側のどのWidgetかは知らない。画面をFlutter化するときに
     * ネイティブ側へコードを足さずに済むのはこのため。
     */
    fun intentFor(context: Context, route: String): Intent {
        initialize(context)
        return FlutterActivity
            .NewEngineInGroupIntentBuilder(
                FlutterScreenActivity::class.java,
                ENGINE_GROUP_ID,
            )
            .initialRoute(route)
            .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.opaque)
            .build(context)
    }
}
