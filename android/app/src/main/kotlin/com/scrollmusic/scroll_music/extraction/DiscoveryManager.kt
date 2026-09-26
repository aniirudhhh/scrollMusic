package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withContext
import kotlin.random.Random

/**
 * Handles fetching dynamic feeds of Indian music from YouTube using NewPipeExtractor.
 *
 * On each call, we pick 2 different random queries and run them in parallel,
 * then merge + deduplicate results. This ensures variety across app sessions
 * and fills the initial feed fast.
 */
class DiscoveryManager {

    companion object {
        // Dynamic components for high variety initial feeds
        private val BHOJPURI_SINGERS = listOf(
            "Pawan Singh", "Khesari Lal Yadav", "Shilpi Raj", "Ritesh Pandey", 
            "Pramod Premi", "Arvind Akela Kallu", "Neelkamal Singh", "Gunjan Singh", "Raushan Rohi"
        )
        private val BHOJPURI_STYLES = listOf(
            "superhit songs audio", "dj remix audio", "romantic songs audio",
            "viral hit audio", "sad songs audio", "mashup audio", "lofi audio"
        )

        private val HINDI_SINGERS = listOf(
            "Kumar Sanu", "Udit Narayan", "Alka Yagnik", "Lata Mangeshkar", 
            "Kishore Kumar", "Arijit Singh", "Shreya Ghoshal", "Sonu Nigam", "Atif Aslam"
        )
        private val HINDI_STYLES = listOf(
            "90s hit songs audio", "romantic hits audio", "sad songs audio",
            "80s superhit audio", "lofi mashup audio", "unplugged cover audio"
        )

        // Max duration in seconds to avoid 1-hour jukeboxes
        private const val MAX_DURATION_SECONDS = 7 * 60L // 7 minutes

        // YouTube thumbnail quality URL templates (highest -> fallback)
        fun buildThumbnailUrl(videoId: String): String {
            // maxresdefault is 1280x720 HD.
            return "https://i.ytimg.com/vi/$videoId/maxresdefault.jpg"
        }

        fun buildFallbackThumbnailUrl(videoId: String): String {
            // hqdefault is 480x360 - always available on YouTube.
            return "https://i.ytimg.com/vi/$videoId/hqdefault.jpg"
        }
    }

    private fun pickFreshBhojpuri(): String {
        val singer = BHOJPURI_SINGERS.random()
        val style = BHOJPURI_STYLES.random()
        return "$singer $style"
    }

    private fun pickFreshMix(): String {
        val singer = HINDI_SINGERS.random()
        val style = HINDI_STYLES.random()
        return "$singer $style"
    }

    /**
     * Fetches a randomized feed of songs by running 2 different queries in parallel.
     * Results are merged, deduplicated by video ID, and shuffled.
     */
    suspend fun fetchDiscoveryFeed(): List<Map<String, String>> =
        withContext(Dispatchers.IO) {
            try {
                val searchManager = CustomSearchManager()
                coroutineScope {
                    val queries = mutableSetOf<String>()
                    while(queries.size < 2) queries.add(pickFreshBhojpuri())
                    while(queries.size < 4) queries.add(pickFreshMix())

                    val deferreds = queries.map { q ->
                        async {
                            try { searchManager.search(q) } catch (e: Exception) { emptyList() }
                        }
                    }

                    val resultsList = deferreds.awaitAll()

                    val allItems = mutableListOf<Map<String, String>>()
                    for (results in resultsList) {
                        allItems.addAll(results.take(6)) // 6 items from 4 different queries = 24 items
                    }

                    val deduplicated = mutableListOf<Map<String, String>>()
                    val acceptedTargets = mutableListOf<TrackMatcher.Target>()
                    val seenIds = mutableSetOf<String>()

                    for (item in allItems.shuffled()) {
                        val id = item["id"] ?: ""
                        if (id.isBlank() || !seenIds.add(id)) continue

                        val target = TrackMatcher.targetOf(item)

                        // Check if this track is essentially the same recording as any already accepted track
                        var isDuplicate = false
                        for (accepted in acceptedTargets) {
                            if (TrackMatcher.score(item, accepted) != null) {
                                isDuplicate = true
                                break
                            }
                        }

                        if (!isDuplicate) {
                            deduplicated.add(item)
                            acceptedTargets.add(target)
                        }
                    }

                    deduplicated
                }
            } catch (e: Exception) {
                throw ExtractionException("Failed to fetch discovery feed: ${e.message}", cause = e)
            }
        }
}
