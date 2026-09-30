package com.scrollmusic.scroll_music.bridge

import android.content.Context
import com.scrollmusic.scroll_music.extraction.ExtractionException
import com.scrollmusic.scroll_music.extraction.ExtractionManager
import com.scrollmusic.scroll_music.playback.NativePlaybackManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.downloader.Downloader

/**
 * FlutterBridge registers the MethodChannels and EventChannel with the Flutter engine
 * and routes calls to [ExtractionManager] and [NativePlaybackManager].
 *
 * Channel contracts (must match native_bridge.dart):
 *   MethodChannel  "com.scrollmusic/extraction"     â†’ extractStream(videoId)
 *   MethodChannel  "com.scrollmusic/playback"       â†’ play, pause, resume, stop, seek
 *   EventChannel   "com.scrollmusic/playback_events" â†’ stateChange, position, error events
 */
class FlutterBridge(private val context: Context) {

    private val extractor = ExtractionManager()
    private val discoveryManager = com.scrollmusic.scroll_music.extraction.DiscoveryManager()
    private val searchManager = com.scrollmusic.scroll_music.extraction.CustomSearchManager()
    private val player = NativePlaybackManager(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // EventChannel sink â€” null when Flutter isn't listening
    private var eventSink: EventChannel.EventSink? = null

    fun setup(
        extractionChannel: MethodChannel,
        playbackChannel: MethodChannel,
        playbackEventChannel: EventChannel,
    ) {
        // Initialize NewPipe with an OkHttp-based downloader.
        // This only needs to happen once per process.
        NewPipe.init(ScrollMusicDownloader)

        extractionChannel.setMethodCallHandler(::handleExtractionCall)
        playbackChannel.setMethodCallHandler(::handlePlaybackCall)

        playbackEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
                NativePlaybackManager.eventSink = { event ->
                    // EventSink.success must be called on the main thread
                    scope.launch(Dispatchers.Main) {
                        sink.success(event)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                NativePlaybackManager.eventSink = null
            }
        })
    }

    // â”€â”€â”€ Extraction calls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private fun handleExtractionCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "extractStream" -> {
                val videoId = call.argument<String>("videoId")
                    ?: return result.error("INVALID_ARGS", "videoId is required", null)

                scope.launch {
                    try {
                        val streamResult = extractor.extractAudioStream(videoId)
                        result.success(
                            mapOf(
                                "url" to streamResult.streamUrl,
                                "fetchedAtMs" to streamResult.fetchedAtMs,
                                "format" to streamResult.format,
                            )
                        )
                    } catch (e: ExtractionException) {
                        result.error("EXTRACTION_FAILED", e.message, null)
                    } catch (e: Exception) {
                        result.error("UNKNOWN", e.message, null)
                    }
                }
            }
            "fetchDiscoveryFeed" -> {
                scope.launch {
                    try {
                        val feed = discoveryManager.fetchDiscoveryFeed()
                        result.success(feed)
                    } catch (e: ExtractionException) {
                        result.error("EXTRACTION_FAILED", e.message, null)
                    } catch (e: Exception) {
                        result.error("UNKNOWN", e.message, null)
                    }
                }
            }
            "search" -> {
                val query = call.argument<String>("query")
                    ?: return result.error("INVALID_ARGS", "query is required", null)
                val filter = call.argument<String>("filter")
                scope.launch {
                    try {
                        val searchResults = searchManager.search(query, filter)
                        result.success(searchResults)
                    } catch (e: Exception) {
                        result.error("SEARCH_FAILED", e.message, null)
                    }
                }
            }
            "fetchRecommendations" -> {
                val videoId = call.argument<String>("videoId")
                    ?: return result.error("INVALID_ARGS", "videoId is required", null)
                scope.launch {
                    try {
                        val recommendations = extractor.fetchRecommendations(videoId)
                        result.success(recommendations)
                    } catch (e: Exception) {
                        result.error("FETCH_RECOMMENDATIONS_FAILED", e.message, null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    // â”€â”€â”€ Playback calls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private fun handlePlaybackCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "playSong" -> {
                val url = call.argument<String>("url")
                    ?: return result.error("INVALID_ARGS", "url is required", null)
                val title = call.argument<String>("title") ?: "Unknown Song"
                val artist = call.argument<String>("artist") ?: "Unknown Artist"
                val artwork = call.argument<String>("artwork") ?: ""
                player.playSong(url, title, artist, artwork)
                result.success(null)
            }
            "pause" -> {
                player.pause()
                result.success(null)
            }
            "resume" -> {
                player.resume()
                result.success(null)
            }
            "stop" -> {
                player.stop()
                result.success(null)
            }
            "seek" -> {
                val posMs = call.argument<Int>("positionMs")?.toLong()
                    ?: return result.error("INVALID_ARGS", "positionMs is required", null)
                player.seekTo(posMs)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                player.setVolume(volume)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun release() {
        player.release()
        scope.cancel()
    }
}

