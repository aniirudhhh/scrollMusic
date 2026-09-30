package com.scrollmusic.scroll_music.extraction

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class CustomSearchManager {
    private val client = OkHttpClient()

    suspend fun search(query: String, filter: String? = null): List<Map<String, String>> = withContext(Dispatchers.IO) {
        val payload = JSONObject().apply {
            put("context", JSONObject().apply {
                put("client", JSONObject().apply {
                    put("clientName", "WEB_REMIX")
                    put("clientVersion", "1.20230508.00.00")
                })
            })
            put("query", query)
            
            // Map the string filter to YTM inner-tube param
            val params = when (filter) {
                "videos" -> "EgWKAQIQAWoKEAkQChAFEAMQBA=="
                "artists" -> "EgWKAQIgAWoKEAkQChAFEAMQBA=="
                "albums" -> "EgWKAQIYAWoKEAkQChAFEAMQBA=="
                "featuredPlaylists", "communityPlaylists", "playlists" -> "EgWKAQIoAWoKEAkQChAFEAMQBA=="
                else -> "EgWKAQIIAWoKEAkQChAFEAMQBA==" // songs default
            }
            put("params", params)
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

        val bodyStr = response.body?.bytes()?.toString(Charsets.UTF_8) ?: throw ExtractionException("Empty response body")
        val json = JSONObject(bodyStr)
        
        val results = mutableListOf<Map<String, String>>()
        
        try {
            val renderers = mutableListOf<JSONObject>()
            collectRenderers(json, "musicResponsiveListItemRenderer", renderers)

            for (item in renderers) {
                val parsed = parseResponsiveListItem(item, filter)
                if (parsed != null) {
                    results.add(parsed)
                }
            }
        } catch (e: Exception) {
            throw Exception("Parse error: ${e.message}", e)
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
    
    private fun parseResponsiveListItem(item: JSONObject, requestedFilter: String?): Map<String, String>? {
        try {
            var extractedId = ""
            var itemType = requestedFilter ?: "songs"

            // 1. Try to find a videoId (Songs, Videos, Episodes)
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
                videoId = item.optJSONArray("flexColumns")?.optJSONObject(0)
                    ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                    ?.optJSONObject("text")
                    ?.optJSONArray("runs")
                    ?.optJSONObject(0)
                    ?.optJSONObject("navigationEndpoint")
                    ?.optJSONObject("watchEndpoint")
                    ?.optString("videoId")
            }

            // 2. If no videoId, try to find a browseId (Artists, Albums, Playlists)
            var browseId = ""
            if (videoId.isNullOrBlank()) {
                browseId = item.optJSONObject("navigationEndpoint")
                    ?.optJSONObject("browseEndpoint")
                    ?.optString("browseId") ?: ""
                
                if (browseId.isBlank()) {
                    browseId = item.optJSONArray("flexColumns")?.optJSONObject(0)
                        ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                        ?.optJSONObject("text")
                        ?.optJSONArray("runs")
                        ?.optJSONObject(0)
                        ?.optJSONObject("navigationEndpoint")
                        ?.optJSONObject("browseEndpoint")
                        ?.optString("browseId") ?: ""
                }
            }

            if (!videoId.isNullOrBlank()) {
                extractedId = videoId
                if (itemType !in listOf("songs", "videos", "episodes")) {
                    itemType = "songs"
                }
            } else if (browseId.isNotBlank()) {
                extractedId = browseId
                if (browseId.startsWith("UC") || browseId.startsWith("FEmusic_library_privately_owned_artist")) {
                    itemType = "artists"
                } else if (browseId.startsWith("MPREb_")) {
                    itemType = "albums"
                } else if (browseId.startsWith("VL") || browseId.startsWith("PL")) {
                    itemType = "playlists"
                }
            } else {
                return null // Unplayable/Unviewable item
            }
            
            val flexColumns = item.optJSONArray("flexColumns") ?: return null
            if (flexColumns.length() < 2 && itemType != "artists") return null
            
            // Extract title
            val titleTextRuns = flexColumns.optJSONObject(0)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
            val title = titleTextRuns?.optJSONObject(0)?.optString("text") ?: "Unknown"
            
            // Extract subtitle details
            val subtitleRuns = flexColumns.optJSONObject(1)
                ?.optJSONObject("musicResponsiveListItemFlexColumnRenderer")
                ?.optJSONObject("text")
                ?.optJSONArray("runs")
                
            val subtitleBuilder = java.lang.StringBuilder()
            if (subtitleRuns != null) {
                for (i in 0 until subtitleRuns.length()) {
                    subtitleBuilder.append(subtitleRuns.optJSONObject(i)?.optString("text") ?: "")
                }
            }
            val subtitleRaw = subtitleBuilder.toString().trim()
            
            // Clean up subtitle to just artist/owner name roughly for now
            val parts = subtitleRaw.split(Regex(" [\\u2022] "))
            val displaySubtitle = if (parts.size > 1 && (parts[0].equals("Song", true) || parts[0].equals("Video", true))) {
                parts[1]
            } else if (parts.isNotEmpty()) {
                parts[0]
            } else {
                "Unknown"
            }
            
            // Extract thumbnail
            var thumbnailUrl: String? = null
            val outerThumbnails = item.optJSONObject("thumbnail")
                ?.optJSONObject("musicThumbnailRenderer")
                ?.optJSONObject("thumbnail")
                ?.optJSONArray("thumbnails")
            
            if (outerThumbnails != null && outerThumbnails.length() > 0) {
                thumbnailUrl = outerThumbnails.optJSONObject(outerThumbnails.length() - 1)?.optString("url")
            }
            
            if (thumbnailUrl == null) {
                val fallbackThumbnails = item.optJSONArray("thumbnails")
                    ?.optJSONObject(0)
                    ?.optJSONArray("thumbnails")
                if (fallbackThumbnails != null && fallbackThumbnails.length() > 0) {
                    thumbnailUrl = fallbackThumbnails.optJSONObject(fallbackThumbnails.length() - 1)?.optString("url")
                }
            }

            // Replace resize artifacts in YT urls if present
            if (thumbnailUrl != null) {
                if (thumbnailUrl.contains("ytimg.com")) {
                    // Video thumbnails from ytimg are often mqdefault (320x180) which is very blurry.
                    // Strip the query params (which add crops) and upgrade to hqdefault (480x360) which always exists.
                    thumbnailUrl = thumbnailUrl.substringBefore("?")
                        .replace("mqdefault.jpg", "hqdefault.jpg")
                        .replace("sddefault.jpg", "hqdefault.jpg")
                        .replace("default.jpg", "hqdefault.jpg")
                } else {
                    // For lh3.googleusercontent.com, request a crisp 1080x1080 square
                    thumbnailUrl = thumbnailUrl.replace(Regex("=w\\d+-h\\d+.*"), "=w1080-h1080-l90-rj")
                }
            }

            return mapOf(
                "id" to extractedId,
                "title" to title,
                "artist" to displaySubtitle, // used as generic subtitle
                "artwork" to (thumbnailUrl ?: ""),
                "type" to itemType
            )
        } catch (e: Exception) {
            return null
        }
    }
    
    // Ignore duration logic here for brevity, we handle filtering by type
    private fun isTooLong(item: JSONObject): Boolean {
        return false 
    }
}



