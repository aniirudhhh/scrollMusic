package com.scrollmusic.scroll_music.playback

import android.content.ComponentName
import android.content.Context
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class NativePlaybackManager(private val context: Context) {
    companion object {
        var eventSink: ((Map<String, Any?>) -> Unit)? = null
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var positionJob: Job? = null
    
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var controller: MediaController? = null

    init {
        initializeController()
    }

    private fun initializeController() {
        val sessionToken = SessionToken(context, ComponentName(context, PlaybackService::class.java))
        
        val controllerListener = object : MediaController.Listener {
            override fun onDisconnected(controller: MediaController) {
                super.onDisconnected(controller)
                stopPositionPolling()
                this@NativePlaybackManager.controller = null
                emitEvent(mapOf("type" to "stateChange", "state" to "idle"))
                // Re-initialize for future playback (e.g. user tapping play in the app)
                initializeController()
            }
        }

        controllerFuture = MediaController.Builder(context, sessionToken)
            .setListener(controllerListener)
            .buildAsync()
        
        controllerFuture?.addListener({
            controller = controllerFuture?.get()
            controller?.addListener(playerListener)
        }, MoreExecutors.directExecutor())
    }

    fun playSong(streamUrl: String, title: String, artist: String, artwork: String) {
        val c = controller
        if (c == null) {
            // If controller isn't ready yet, retry in 100ms
            scope.launch {
                delay(100)
                playSong(streamUrl, title, artist, artwork)
            }
            return
        }
        
        scope.launch {
            val metadata = MediaMetadata.Builder()
                .setTitle(title)
                .setArtist(artist)
                .setArtworkUri(android.net.Uri.parse(artwork))
                .build()
                
            val mediaItem = MediaItem.Builder()
                .setUri(streamUrl)
                .setMediaMetadata(metadata)
                .build()

            c.setMediaItem(mediaItem)
            c.prepare()
            c.playWhenReady = true
        }
    }

    fun pause() {
        scope.launch { controller?.pause() }
    }

    fun resume() {
        scope.launch { controller?.play() }
    }

    fun stop() {
        scope.launch {
            controller?.stop()
            controller?.clearMediaItems()
        }
    }

    fun seekTo(positionMs: Long) {
        scope.launch { controller?.seekTo(positionMs) }
    }

    fun setVolume(volume: Float) {
        scope.launch { controller?.volume = volume.coerceIn(0f, 1f) }
    }

    fun release() {
        positionJob?.cancel()
        controller?.removeListener(playerListener)
        controllerFuture?.let { MediaController.releaseFuture(it) }
        scope.cancel()
    }

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            val c = controller ?: return
            when (playbackState) {
                Player.STATE_BUFFERING -> {
                    emitEvent(mapOf("type" to "stateChange", "state" to "buffering"))
                    stopPositionPolling()
                }
                Player.STATE_READY -> {
                    val stateStr = if (c.playWhenReady) "playing" else "paused"
                    emitEvent(mapOf("type" to "stateChange", "state" to stateStr))
                    if (c.playWhenReady) startPositionPolling() else stopPositionPolling()
                }
                Player.STATE_ENDED -> {
                    stopPositionPolling()
                    emitEvent(mapOf("type" to "ended"))
                    emitEvent(mapOf("type" to "stateChange", "state" to "idle"))
                }
                Player.STATE_IDLE -> {
                    stopPositionPolling()
                    emitEvent(mapOf("type" to "stateChange", "state" to "idle"))
                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            val state = if (isPlaying) "playing" else "paused"
            emitEvent(mapOf("type" to "stateChange", "state" to state))
            if (isPlaying) startPositionPolling() else stopPositionPolling()
        }

        override fun onPlayerError(error: PlaybackException) {
            stopPositionPolling()
            emitEvent(
                mapOf(
                    "type" to "error",
                    "message" to (error.message ?: "Playback error"),
                    "code" to error.errorCode,
                )
            )
        }
    }

    private fun startPositionPolling() {
        positionJob?.cancel()
        positionJob = scope.launch {
            while (isActive) {
                val c = controller
                if (c != null) {
                    val pos = c.currentPosition
                    val dur = c.duration.takeIf { it != C.TIME_UNSET } ?: 0L
                    emitEvent(
                        mapOf(
                            "type" to "position",
                            "positionMs" to pos,
                            "durationMs" to dur,
                        )
                    )
                }
                delay(500)
            }
        }
    }

    private fun stopPositionPolling() {
        positionJob?.cancel()
        positionJob = null
    }

    private fun emitEvent(event: Map<String, Any?>) {
        eventSink?.invoke(event)
    }
}
