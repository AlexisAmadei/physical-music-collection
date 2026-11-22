package com.kiwidev.physical.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/** Remote catalog lookup. Returns prefilled Disc drafts (id = 0). */
object MusicBrainz {
    suspend fun byBarcode(code: String) = query("barcode:$code").map { it.copy(barcode = code) }

    suspend fun search(text: String) = query(text)

    private suspend fun query(q: String): List<Disc> = withContext(Dispatchers.IO) {
        runCatching {
            val url = URL("https://musicbrainz.org/ws/2/release/?fmt=json&limit=15&query=" + URLEncoder.encode(q, "UTF-8"))
            val con = url.openConnection() as HttpURLConnection
            con.setRequestProperty("User-Agent", "VinylCollectionApp/0.1 ( https://github.com )")
            con.connectTimeout = 8000; con.readTimeout = 8000
            val json = JSONObject(con.inputStream.bufferedReader().use { it.readText() })
            val rels = json.getJSONArray("releases")
            (0 until rels.length()).map { i ->
                val r = rels.getJSONObject(i)
                val artist = r.optJSONArray("artist-credit")?.let { ac ->
                    (0 until ac.length()).joinToString("") { j ->
                        ac.getJSONObject(j).let { it.optString("name") + it.optString("joinphrase") }
                    }
                } ?: ""
                val media = r.optJSONArray("media")?.optJSONObject(0)?.optString("format") ?: ""
                Disc(
                    title = r.optString("title"),
                    artist = artist,
                    year = r.optString("date").take(4).toIntOrNull(),
                    format = if (media.contains("CD", true)) Format.CD else Format.VINYL,
                    barcode = r.optString("barcode").ifBlank { null },
                    // Cover Art Archive; 404s (no art) fall back to the placeholder.
                    coverUrl = r.optString("id").ifBlank { null }?.let { "https://coverartarchive.org/release/$it/front-500" },
                )
            }
        }.getOrDefault(emptyList())
    }
}
