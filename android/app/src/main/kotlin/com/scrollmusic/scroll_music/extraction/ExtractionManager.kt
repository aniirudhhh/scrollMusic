package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.stream.StreamExtractor
import org.schabi.newpipe.extractor.stream.StreamInfo

/**
 * Extracts a direct audio stream URL for a YouTube video using NewPipeExtractor.
 *
 * This runs entirely on-device — no subprocess, no Python, no backend.
 * NewPipe reverse-engineers YouTube's internal API to retrieve stream URLs.
 *
 * Callers receive a [StreamResult] which contains either a URL or an error.
 * The FlutterBridge converts this result into a MethodChannel response.
 */
class ExtractionManager {

    companion object {
        private const val YOUTUBE_URL_PREFIX = "https://www.youtube.com/watch?v="

        /**
         * Best audio quality preference order.
         * We prefer opus (webm) for efficiency, then m4a as fallback.
         */
        private val PREFERRED_FORMATS = listOf("opus", "webm", "m4a", "mp4")
    }

    private val discoveryManager = DiscoveryManager()
    private val customSearchManager = CustomSearchManager()
    private val recommendationsManager = RecommendationsManager()

    suspend fun search(query: String): List<Map<String, String>> {
        return customSearchManager.search(query)
    }

    suspend fun fetchRecommendations(videoId: String): List<Map<String, String>> {
        return recommendationsManager.getRecommendations(videoId)
    }

    /**
     * Extract the best available audio stream URL for [videoId].
     * Must be called from a coroutine (suspends on IO dispatcher).
     *
     * @throws ExtractionException on any failure
     */
    suspend fun extractAudioStream(videoId: String): StreamResult =
        withContext(Dispatchers.IO) {
            val url = "$YOUTUBE_URL_PREFIX$videoId"
            try {
                val streamInfo = StreamInfo.getInfo(
                    ServiceList.YouTube,
                    url,
                )
                val audioStream = pickBestAudioStream(streamInfo.audioStreams)
                    ?: throw ExtractionException("No suitable audio stream found for $videoId")

                val streamUrl = audioStream.content
                    ?: throw ExtractionException("Audio stream URL is null for $videoId")

                StreamResult(
                    videoId = videoId,
                    streamUrl = streamUrl,
                    // YouTube stream URLs typically expire in 6 hours.
                    // We store the fetch time and let the Dart side check expiry.
                    fetchedAtMs = System.currentTimeMillis(),
                    format = audioStream.format?.name ?: "unknown",
                )
            } catch (e: ExtractionException) {
                throw e
            } catch (e: Exception) {
                throw ExtractionException(
                    "Failed to extract stream for $videoId: ${e.message}",
                    cause = e,
                )
            }
        }

    /**
     * Pick the highest-quality audio stream, preferring our preferred formats.
     * Falls back to highest bitrate from any available stream.
     */
    private fun pickBestAudioStream(streams: List<AudioStream>): AudioStream? {
        if (streams.isEmpty()) return null

        // Try preferred formats in order
        for (format in PREFERRED_FORMATS) {
            val match = streams
                .filter { it.format?.mimeType?.contains(format, ignoreCase = true) == true }
                .maxByOrNull { it.averageBitrate }
            if (match != null) return match
        }

        // Fallback: highest bitrate from anything available
        return streams.maxByOrNull { it.averageBitrate }
    }
}

/** Holds a successfully extracted audio stream. */
data class StreamResult(
    val videoId: String,
    val streamUrl: String,
    val fetchedAtMs: Long,
    val format: String,
)

/** Thrown when extraction fails for any reason. */
class ExtractionException(
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause)
