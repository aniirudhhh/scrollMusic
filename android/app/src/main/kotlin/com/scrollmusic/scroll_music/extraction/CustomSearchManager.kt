package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * A custom search manager that queries YouTube Music's internal API directly,
 * bypassing external extractors like NewPipeExtractor for faster and more controlled
 * search results.
 */
class CustomSearchManager {
    private val client = OkHttpClient()

    suspend fun search(query: String): List<Map<String, String>> = withContext(Dispatchers.IO) {
        // Construct the undocumented YouTube Music inner-tube API payload
        val payload = JSONObject().apply {
            put("context", JSONObject().apply {
                put("client", JSONObject().apply {
                    put("clientName", "WEB_REMIX")
                    put("clientVersion", "1.20230508.00.00") // Required to get valid responses
                })
            })
            put("query", query)
            put("params", "EgWKAQIIAWoKEAkQChAFEAMQBA==") // Filter for SONGS
        }

        val request = Request.Builder()
            .url("https://music.youtube.com/youtubei/v1/search")
            .post(payload.toString().toRequestBody("application/json".toMediaType()))
            .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            .header("Origin", "https://music.youtube.com")
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw ExtractionException("Search failed with code ${response.code}")
        }

        val bodyStr = response.body?.string() ?: throw ExtractionException("Empty response body")
        val json = JSONObject(bodyStr)
        
        val results = mutableListOf<Map<String, String>>()
        
        try {
            val renderers = mutableListOf<JSONObject>()
            collectRenderers(json, "musicResponsiveListItemRenderer", renderers)

            for (item in renderers) {
                val parsed = parseResponsiveListItem(item)
                if (parsed != null) {
                    results.add(parsed)
                }
            }
        } catch (e: Exception) {
            throw Exception("Parse error: ${e.message}", e)
        }
        
        if (results.isEmpty()) {
            throw Exception("No results found. Body sample: " + bodyStr.take(500))
        }
        
        results
    }
    
    private fun collectRenderers(node: Any?, keyToFind: String, out: MutableList<JSONObject>) {
        if (node is JSONObject) {
            val found = node.optJSONObject(keyToFind)
            if (found != null) {
                out.add(found)
            }
            val keys = node.keys()
            while (keys.hasNext()) {
                collectRenderers(node.opt(keys.next()), keyToFind, out)
            }
        } else if (node is org.json.JSONArray) {
            for (i in 0 until node.length()) {
                collectRenderers(node.opt(i), keyToFind, out)
            }
        }
    }
    
    private fun parseResponsiveListItem(item: JSONObject): Map<String, String>? {
        try {
            // videoId dictates whether this is a playable song
            var videoId = item.optJSONObject("playlistItemData")?.optString("videoId")
            if (videoId.isNullOrBlank()) {
                videoId = item.optJSONObject("overlay")
                    ?.optJSONObject("musicItemThumbnailOverlayRenderer")
                    ?.optJSONObject("content")
                    ?.optJSONObject("musicPlayButtonRenderer")
                    ?.optJSONObject("playNavigationEndpoint")
                    ?.optJSONObject("watchEndpoint")
                    ?.optString("videoId")
            }
            if (videoId.isNullOrBlank()) {
                // sometimes the structure is slightly different for songs in search results
                val firstColumn = item.optJSONArray("flexColumns")?.optJSONObject(0)
                videoId = firstColumn?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                    ?.optJSONObject("text")
                    ?.optJSONArray("runs")
                    ?.optJSONObject(0)
                    ?.optJSONObject("navigationEndpoint")
                    ?.optJSONObject("watchEndpoint")
                    ?.optString("videoId")
            }
            if (videoId.isNullOrBlank()) return null
            
            if (isTooLong(item)) return null
            
            val flexColumns = item.optJSONArray("flexColumns") ?: return null
            if (flexColumns.length() < 2) return null
            
            // Extract title from the first column
            val titleTextRuns = flexColumns.optJSONObject(0)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
            val title = titleTextRuns?.optJSONObject(0)?.optString("text") ?: "Unknown Title"
            
            // Extract artist/album from the second column
            val artistTextRuns = flexColumns.optJSONObject(1)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
                
            val artistBuilder = StringBuilder()
            if (artistTextRuns != null) {
                for (i in 0 until artistTextRuns.length()) {
                    val text = artistTextRuns.optJSONObject(i)?.optString("text") ?: ""
                    
                    // Skip the separator for the final artist string
                    val trimmed = text.trim()
                    if (trimmed.equals("Song", ignoreCase = true) || trimmed.equals("Video", ignoreCase = true)) {
                        continue
                    }
                    
                    if (trimmed == "•") {
                        if (artistBuilder.isNotEmpty()) {
                            break // We've captured the artist section, ignore album and duration
                        }
                        continue
                    }
                    
                    artistBuilder.append(text)
                }
            }
            val artist = artistBuilder.toString().trim().ifBlank { "Unknown Artist" }
            
            // Extract original high-res square thumbnail if available
            var thumbnailUrl: String? = null
            val thumbnails = item.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("thumbnail")
                ?.optJSONObject("musicThumbnailRenderer")
                ?.optJSONObject("thumbnail")
                ?.optJSONArray("thumbnails")
            
            if (thumbnails == null) {
                // Try alternate structure for thumbnails
                val fallbackThumbnails = item.optJSONArray("thumbnails")
                    ?.optJSONObject(0)
                    ?.optJSONArray("thumbnails")
                if (fallbackThumbnails != null && fallbackThumbnails.length() > 0) {
                    thumbnailUrl = fallbackThumbnails.optJSONObject(fallbackThumbnails.length() - 1)?.optString("url")
                } else {
                    // One more structure: outer thumbnail
                    val outerThumbnails = item.optJSONObject("thumbnail")
                        ?.optJSONObject("musicThumbnailRenderer")
                        ?.optJSONObject("thumbnail")
                        ?.optJSONArray("thumbnails")
                    if (outerThumbnails != null && outerThumbnails.length() > 0) {
                        thumbnailUrl = outerThumbnails.optJSONObject(outerThumbnails.length() - 1)?.optString("url")
                    }
                }
            } else if (thumbnails.length() > 0) {
                // Get the highest resolution thumbnail (usually the last one in the array)
                thumbnailUrl = thumbnails.optJSONObject(thumbnails.length() - 1)?.optString("url")
            }

            // If it's a googleusercontent URL, request a 1080x1080 crisp version
            if (thumbnailUrl != null && thumbnailUrl.contains("googleusercontent.com")) {
                // Usually looks like ...=w120-h120-l90-rj or ...=w60-h60-c
                thumbnailUrl = thumbnailUrl.replace(Regex("=w\\d+-h\\d+.*"), "=w1080-h1080-l90-rj")
            }

            // Extract duration from fixed/flex columns
            var durationText = ""
            val fixedColumns = item.optJSONArray("fixedColumns")
            if (fixedColumns != null) {
                for (i in 0 until fixedColumns.length()) {
                    val runs = fixedColumns.optJSONObject(i)
                        ?.optJSONObject("musicResponsiveListItemFixedColumnRenderer")
                        ?.optJSONObject("text")
                        ?.optJSONArray("runs")
                    if (runs != null) {
                        for (j in 0 until runs.length()) {
                            val text = runs.optJSONObject(j)?.optString("text") ?: ""
                            if (text.contains(":")) {
                                durationText = text
                            }
                        }
                    }
                }
            }

            val finalArtwork = thumbnailUrl ?: DiscoveryManager.buildThumbnailUrl(videoId)

            return mapOf(
                "id" to videoId,
                "title" to title,
                "artist" to artist,
                "artwork" to finalArtwork,
                "artworkFallback" to DiscoveryManager.buildFallbackThumbnailUrl(videoId),
                "durationText" to durationText
            )
        } catch (e: Exception) {
            return null
        }
    }

    private fun isTooLong(item: JSONObject): Boolean {
        val texts = mutableListOf<String>()
        
        val flexColumns = item.optJSONArray("flexColumns")
        if (flexColumns != null) {
            for (i in 0 until flexColumns.length()) {
                val runs = flexColumns.optJSONObject(i)
                    ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                    ?.optJSONObject("text")
                    ?.optJSONArray("runs")
                if (runs != null) {
                    for (j in 0 until runs.length()) {
                        texts.add(runs.optJSONObject(j)?.optString("text") ?: "")
                    }
                }
            }
        }
        
        val fixedColumns = item.optJSONArray("fixedColumns")
        if (fixedColumns != null) {
            for (i in 0 until fixedColumns.length()) {
                val runs = fixedColumns.optJSONObject(i)
                    ?.optJSONObject("musicResponsiveListItemFixedColumnRenderer")
                    ?.optJSONObject("text")
                    ?.optJSONArray("runs")
                if (runs != null) {
                    for (j in 0 until runs.length()) {
                        texts.add(runs.optJSONObject(j)?.optString("text") ?: "")
                    }
                }
            }
        }
        
        for (text in texts) {
            if (Regex("\\b\\d+:\\d{2}:\\d{2}\\b").containsMatchIn(text)) return true
            
            val mmssMatch = Regex("\\b(\\d{2,}):(\\d{2})\\b").find(text)
            if (mmssMatch != null) {
                val minutes = mmssMatch.groupValues[1].toIntOrNull() ?: 0
                if (minutes >= 15) return true
            }
            
            if (text.contains("Podcast", ignoreCase = true) || text.contains("Episode", ignoreCase = true)) return true
        }
        
        return false
    }
}
