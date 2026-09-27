package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import kotlin.random.Random

/**
 * Handles fetching dynamic feeds of Indian music from YouTube using NewPipeExtractor.
 * Also supports authenticated YouTube Music Home Feed fetching if logged in.
 */
class DiscoveryManager {

    companion object {
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

        private const val MAX_DURATION_SECONDS = 7 * 60L

        fun buildThumbnailUrl(videoId: String): String {
            return "https://i.ytimg.com/vi/$videoId/maxresdefault.jpg"
        }

        fun buildFallbackThumbnailUrl(videoId: String): String {
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

    private suspend fun fetchAuthenticatedHomeFeed(): List<Map<String, String>>? = withContext(Dispatchers.IO) {
        val cookie = android.webkit.CookieManager.getInstance().getCookie("https://music.youtube.com") ?: 
                     android.webkit.CookieManager.getInstance().getCookie("https://youtube.com")
        if (cookie?.contains("SAPISID") != true) return@withContext null

        try {
            val client = OkHttpClient()
            val payload = JSONObject().apply {
                put("context", JSONObject().apply {
                    put("client", JSONObject().apply {
                        put("clientName", "WEB_REMIX")
                        put("clientVersion", "1.20230508.00.00")
                    })
                })
                put("browseId", "FEmusic_home")
            }

            val request = Request.Builder()
                .url("https://music.youtube.com/youtubei/v1/browse")
                .post(payload.toString().toRequestBody("application/json".toMediaType()))
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                .header("Origin", "https://music.youtube.com")
                .header("Cookie", cookie)
                .build()

            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return@withContext null
            val bodyStr = response.body?.string() ?: return@withContext null
            val json = JSONObject(bodyStr)
            
            val results = mutableListOf<Map<String, String>>()
            val listRenderers = mutableListOf<JSONObject>()
            
            // Extract playable songs from "Quick picks", "Listen again", "Mixed for you" carousels
            RecommendationsManager.collectRenderers(json, "musicResponsiveListItemRenderer", listRenderers)
            
            for (item in listRenderers) {
                val parsed = RecommendationsManager.parseResponsiveListItem(item)
                if (parsed != null) {
                    results.add(parsed)
                }
            }
            
            val distinctResults = results.distinctBy { it["id"] }
            if (distinctResults.isNotEmpty()) {
                return@withContext distinctResults.shuffled()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        null
    }

    suspend fun fetchDiscoveryFeed(): List<Map<String, String>> =
        withContext(Dispatchers.IO) {
            try {
                // 1. Try Authenticated Home Feed first
                val authFeed = fetchAuthenticatedHomeFeed()
                if (authFeed != null && authFeed.isNotEmpty()) {
                    return@withContext authFeed
                }

                // 2. Fallback to random NewPipe query engine
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
                        allItems.addAll(results.take(6))
                    }

                    val deduplicated = mutableListOf<Map<String, String>>()
                    val acceptedTargets = mutableListOf<TrackMatcher.Target>()
                    val seenIds = mutableSetOf<String>()

                    for (item in allItems.shuffled()) {
                        val id = item["id"] ?: ""
                        if (id.isBlank() || !seenIds.add(id)) continue

                        val target = TrackMatcher.targetOf(item)

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
