package com.scrollmusic.scroll_music.bridge

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.MediaType.Companion.toMediaType
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request as NewPipeRequest
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import java.util.concurrent.TimeUnit

/**
 * NewPipe requires a [Downloader] implementation to make HTTP requests.
 * We use OkHttp — the same library used by Flutter's http package on Android.
 *
 * This is a minimal implementation suitable for stream extraction.
 * It does NOT handle cookies, CAPTCHAs, or authentication.
 */
object ScrollMusicDownloader : Downloader() {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    // A browser-like user-agent helps avoid YouTube bot detection.
    private const val USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) " +
        "Chrome/127.0.0.0 Mobile Safari/537.36"

    override fun execute(request: NewPipeRequest): Response {
        val httpMethod = request.httpMethod()
        val url = request.url()
        val headers = request.headers()
        val body = request.dataToSend()

        val requestBuilder = Request.Builder().url(url)

        // Forward all headers from NewPipe's request
        headers.forEach { (name, values) ->
            values.forEach { value -> requestBuilder.addHeader(name, value) }
        }

        // Set a realistic user-agent if not already set
        if (headers["User-Agent"] == null) {
            requestBuilder.addHeader("User-Agent", USER_AGENT)
        }

        // Build the request body based on HTTP method
        val okHttpRequest = when (httpMethod) {
            "GET" -> requestBuilder.get().build()
            "POST" -> {
                val mediaType = "application/json".toMediaType()
                val requestBody = (body ?: ByteArray(0)).toRequestBody(mediaType)
                requestBuilder.post(requestBody).build()
            }
            else -> requestBuilder.get().build()
        }

        val response = client.newCall(okHttpRequest).execute()

        if (response.code == 429) {
            // YouTube rate-limited us — NewPipe handles this as a ReCaptchaException
            throw ReCaptchaException("YouTube rate limit hit", url)
        }

        val responseBody = response.body?.string() ?: ""
        val responseHeaders = response.headers.toMultimap()

        return Response(
            response.code,
            response.message,
            responseHeaders,
            responseBody,
            url,
        )
    }
}
