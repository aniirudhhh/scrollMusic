package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * Handles fetching the auto-play queue (Up Next) from YouTube Music's internal API.
 */
class RecommendationsManager {
    private val client = OkHttpClient()

    suspend fun getRecommendations(videoId: String): List<Map<String, String>> = withContext(Dispatchers.IO) {
        val cookie = android.webkit.CookieManager.getInstance().getCookie("https://music.youtube.com") ?: 
                     android.webkit.CookieManager.getInstance().getCookie("https://youtube.com")
        val isLoggedIn = cookie?.contains("SAPISID") == true

        val payload = JSONObject().apply {
            put("context", JSONObject().apply {
                put("client", JSONObject().apply {
                    put("clientName", "WEB_REMIX")
                    put("clientVersion", "1.20230508.00.00")
                })
            })
            put("videoId", videoId)
            
            if (isLoggedIn) {
                // For authenticated users, the Radio engine generates perfect taste profiles
                put("playlistId", "RDAMVM$videoId")
            } else {
                // Explicitly excluding RDAMVM for guests to prevent regional drift
            }
        }

        val requestBuilder = Request.Builder()
            .url("https://music.youtube.com/youtubei/v1/next")
            .post(payload.toString().toRequestBody("application/json".toMediaType()))
            .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            .header("Origin", "https://music.youtube.com")

        if (isLoggedIn && cookie != null) {
            requestBuilder.header("Cookie", cookie)
        }

        val request = requestBuilder.build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw ExtractionException("Recommendations failed with code ${response.code}")
        }

        val bodyStr = response.body?.string() ?: throw ExtractionException("Empty response body")
        val json = JSONObject(bodyStr)
        
        val results = mutableListOf<Map<String, String>>()
        
        try {
            val panelRenderers = mutableListOf<JSONObject>()
            collectRenderers(json, "playlistPanelVideoRenderer", panelRenderers)
            
            for (item in panelRenderers) {
                val parsed = parsePlaylistPanelVideoRenderer(item)
                if (parsed != null && parsed["id"] != videoId) {
                    results.add(parsed)
                }
            }
            
            if (results.isEmpty()) {
                val listRenderers = mutableListOf<JSONObject>()
                collectRenderers(json, "musicResponsiveListItemRenderer", listRenderers)

                for (item in listRenderers) {
                    val parsed = parseResponsiveListItem(item)
                    if (parsed != null && parsed["id"] != videoId) {
                        results.add(parsed)
                    }
                }
            }
        } catch (e: Exception) {
            throw Exception("Parse error: ${e.message}", e)
        }
        
        results
    }
    
    companion object {
fun collectRenderers(node: Any?, keyToFind: String, out: MutableList<JSONObject>) {
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
    
    fun parsePlaylistPanelVideoRenderer(item: JSONObject): Map<String, String>? {
        try {
            val videoId = item.optString("videoId")
            if (videoId.isNullOrBlank()) return null
            
            val lengthText = item.optJSONObject("lengthText")?.optJSONArray("runs")?.optJSONObject(0)?.optString("text") ?: ""
            if (lengthText.count { it == ':' } >= 2) return null
            val mmssMatch = Regex("^(\\d{2,}):(\\d{2})$").find(lengthText)
            if (mmssMatch != null) {
                val minutes = mmssMatch.groupValues[1].toIntOrNull() ?: 0
                if (minutes >= 15) return null
            }
            
            val title = item.optJSONObject("title")?.optJSONArray("runs")?.optJSONObject(0)?.optString("text") ?: "Unknown Title"
            
            val artistBuilder = StringBuilder()
            val bylineRuns = item.optJSONObject("longBylineText")?.optJSONArray("runs")
            if (bylineRuns != null) {
                for (i in 0 until bylineRuns.length()) {
                    val text = bylineRuns.optJSONObject(i)?.optString("text") ?: ""
                    val trimmed = text.trim()
                    if (trimmed == "•") break
                    artistBuilder.append(text)
                }
            }
            val artist = artistBuilder.toString().trim().ifBlank { "Unknown Artist" }
            
            var thumbnailUrl: String? = null
            val thumbnails = item.optJSONObject("thumbnail")?.optJSONArray("thumbnails")
            if (thumbnails != null && thumbnails.length() > 0) {
                thumbnailUrl = thumbnails.optJSONObject(thumbnails.length() - 1)?.optString("url")
            }
            if (thumbnailUrl != null && thumbnailUrl.contains("googleusercontent.com")) {
                thumbnailUrl = thumbnailUrl.replace(Regex("=w\\d+-h\\d+.*"), "=w1080-h1080-l90-rj")
            }
            val finalArtwork = thumbnailUrl ?: DiscoveryManager.buildThumbnailUrl(videoId)

            return mapOf(
                "id" to videoId,
                "title" to title,
                "artist" to artist,
                "artwork" to finalArtwork,
                "artworkFallback" to DiscoveryManager.buildFallbackThumbnailUrl(videoId)
            )
        } catch (e: Exception) {
            return null
        }
    }

    fun parseResponsiveListItem(item: JSONObject): Map<String, String>? {
        try {
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
            
            val titleTextRuns = flexColumns.optJSONObject(0)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
            val title = titleTextRuns?.optJSONObject(0)?.optString("text") ?: "Unknown Title"
            
            val artistTextRuns = flexColumns.optJSONObject(1)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
                
            val artistBuilder = StringBuilder()
            if (artistTextRuns != null) {
                for (i in 0 until artistTextRuns.length()) {
                    val text = artistTextRuns.optJSONObject(i)?.optString("text") ?: ""
                    
                    val trimmed = text.trim()
                    if (trimmed.equals("Song", ignoreCase = true) || trimmed.equals("Video", ignoreCase = true)) {
                        continue
                    }
                    
                    if (trimmed == "•") {
                        if (artistBuilder.isNotEmpty()) {
                            break
                        }
                        continue
                    }
                    
                    artistBuilder.append(text)
                }
            }
            val artist = artistBuilder.toString().trim().ifBlank { "Unknown Artist" }
            
            var thumbnailUrl: String? = null
            val thumbnails = item.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("thumbnail")
                ?.optJSONObject("musicThumbnailRenderer")
                ?.optJSONObject("thumbnail")
                ?.optJSONArray("thumbnails")
            
            if (thumbnails == null) {
                val fallbackThumbnails = item.optJSONArray("thumbnails")
                    ?.optJSONObject(0)
                    ?.optJSONArray("thumbnails")
                if (fallbackThumbnails != null && fallbackThumbnails.length() > 0) {
                    thumbnailUrl = fallbackThumbnails.optJSONObject(fallbackThumbnails.length() - 1)?.optString("url")
                } else {
                    val outerThumbnails = item.optJSONObject("thumbnail")
                        ?.optJSONObject("musicThumbnailRenderer")
                        ?.optJSONObject("thumbnail")
                        ?.optJSONArray("thumbnails")
                    if (outerThumbnails != null && outerThumbnails.length() > 0) {
                        thumbnailUrl = outerThumbnails.optJSONObject(outerThumbnails.length() - 1)?.optString("url")
                    }
                }
            } else if (thumbnails.length() > 0) {
                thumbnailUrl = thumbnails.optJSONObject(thumbnails.length() - 1)?.optString("url")
            }

            if (thumbnailUrl != null && thumbnailUrl.contains("googleusercontent.com")) {
                thumbnailUrl = thumbnailUrl.replace(Regex("=w\\d+-h\\d+.*"), "=w1080-h1080-l90-rj")
            }

            val finalArtwork = thumbnailUrl ?: DiscoveryManager.buildThumbnailUrl(videoId)

            return mapOf(
                "id" to videoId,
                "title" to title,
                "artist" to artist,
                "artwork" to finalArtwork,
                "artworkFallback" to DiscoveryManager.buildFallbackThumbnailUrl(videoId)
            )
        } catch (e: Exception) {
            return null
        }
    }

    fun isTooLong(item: JSONObject): Boolean {
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
}

