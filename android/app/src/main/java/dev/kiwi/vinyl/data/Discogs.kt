package dev.kiwi.vinyl.data

import dev.kiwi.vinyl.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Discogs database search. Returns prefilled Disc drafts (id = 0), CD and vinyl releases only.
 *
 * Auth: app key/secret from local.properties (`discogs.key`, `discogs.secret`) or the
 * DISCOGS_KEY / DISCOGS_SECRET env vars at build time. Without them search still works,
 * but Discogs omits cover images and allows 25 req/min instead of 60.
 * The OAuth 1.0a flow is only needed for user data (collection, wantlist) — not used here.
 */
object Discogs {
    suspend fun byBarcode(code: String) = query("barcode" to code).map { it.copy(barcode = code) }

    suspend fun search(text: String) = query("q" to text)

    private suspend fun query(param: Pair<String, String>): List<Disc> = withContext(Dispatchers.IO) {
        runCatching {
            val url = URL("https://api.discogs.com/database/search?type=release&per_page=30&${param.first}=" + URLEncoder.encode(param.second, "UTF-8"))
            val con = url.openConnection() as HttpURLConnection
            con.setRequestProperty("User-Agent", "VinylCollectionApp/0.1")
            if (BuildConfig.DISCOGS_KEY.isNotBlank()) {
                con.setRequestProperty("Authorization", "Discogs key=${BuildConfig.DISCOGS_KEY}, secret=${BuildConfig.DISCOGS_SECRET}")
            }
            con.connectTimeout = 8000; con.readTimeout = 8000
            // Non-2xx (bad credentials, 429 rate limit…) throws here → empty → caller falls back.
            val json = JSONObject(con.inputStream.bufferedReader().use { it.readText() })
            val results = json.getJSONArray("results")
            (0 until results.length()).mapNotNull { parse(results.getJSONObject(it)) }
                // One entry per album and format (Discogs lists every pressing), preferring one with a cover.
                .groupBy { Triple(it.title.lowerCase(), it.artist.lowerCase(), it.format) }.values
                .map { pressings -> pressings.firstOrNull { it.coverUrl != null } ?: pressings.first() }
                .take(15)
        }.getOrDefault(emptyList())
    }

    private fun parse(r: JSONObject): Disc? {
        val formats = r.optJSONArray("format").strings()
        val format = when {
            formats.any { it.equals("CD", true) } -> Format.CD
            formats.any { it.equals("Vinyl", true) } -> Format.VINYL
            else -> return null // cassette, file, DVD…
        }
        // "Artist - Title"; Discogs disambiguates artists as "Name (2)" and name variations as "Name*".
        val full = r.optString("title")
        val cut = full.indexOf(" - ")
        val artist = (if (cut >= 0) full.substring(0, cut) else "").replace(Regex("""\s*\(\d+\)|\*"""), "").trim()
        val cover = r.optString("cover_image").takeIf { it.isNotBlank() && !it.endsWith("spacer.gif") }
        return Disc(
            title = if (cut >= 0) full.substring(cut + 3).trim() else full,
            artist = artist,
            year = r.optString("year").toIntOrNull(),
            format = format,
            coverUrl = cover,
        )
    }

    private fun JSONArray?.strings() = if (this == null) emptyList() else (0 until length()).map { optString(it) }
}
