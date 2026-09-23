package com.scrollmusic.scroll_music.playback

import android.content.Intent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

class PlaybackService : MediaSessionService() {

    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()

        val player = ExoPlayer.Builder(this)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                true
            )
            .build()

        val forwardingPlayer = object : androidx.media3.common.ForwardingPlayer(player) {
            override fun getAvailableCommands(): androidx.media3.common.Player.Commands {
                return super.getAvailableCommands().buildUpon()
                    .add(androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT)
                    .add(androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS)
                    .build()
            }

            override fun seekToNext() {
                com.scrollmusic.scroll_music.playback.NativePlaybackManager.eventSink?.invoke(mapOf("type" to "skipNext"))
            }

            override fun seekToPrevious() {
                com.scrollmusic.scroll_music.playback.NativePlaybackManager.eventSink?.invoke(mapOf("type" to "skipPrev"))
            }
        }

        val intent = android.content.Intent(this, com.scrollmusic.scroll_music.MainActivity::class.java)
        val pendingIntent = android.app.PendingIntent.getActivity(
            this, 0, intent,
            android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
        )

        mediaSession = MediaSession.Builder(this, forwardingPlayer)
            .setSessionActivity(pendingIntent)
            .build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    override fun onDestroy() {
        mediaSession?.run {
            player.release()
            release()
        }
        mediaSession = null
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        mediaSession?.player?.pause()
        mediaSession?.player?.stop()
        stopSelf()
        
        // Give Media3 a moment to clear the notification before killing the process
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            android.os.Process.killProcess(android.os.Process.myPid())
        }, 300)
    }
}
