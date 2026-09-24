package com.scrollmusic.scroll_music

import com.scrollmusic.scroll_music.bridge.FlutterBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import android.webkit.CookieManager

class MainActivity : FlutterActivity() {

    private var bridge: FlutterBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val extractionChannel = MethodChannel(messenger, "com.scrollmusic/extraction")
        val playbackChannel = MethodChannel(messenger, "com.scrollmusic/playback")
        val playbackEventChannel = EventChannel(messenger, "com.scrollmusic/playback_events")
        
        val cookieChannel = MethodChannel(messenger, "com.scrollmusic/cookies")
        cookieChannel.setMethodCallHandler { call, result ->
            if (call.method == "getCookies") {
                val url = call.argument<String>("url") ?: "https://youtube.com"
                val cookies = CookieManager.getInstance().getCookie(url)
                result.success(cookies)
            } else {
                result.notImplemented()
            }
        }

        bridge = FlutterBridge(applicationContext).also { b ->
            b.setup(extractionChannel, playbackChannel, playbackEventChannel)
        }
    }

    override fun onDestroy() {
        bridge?.release()
        bridge = null
        super.onDestroy()
    }
}
