package dev.kiwi.vinyl.data

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Dates follow the in-app [Language], never the device region: "3 nov. 2024" / "Nov 3, 2024". */
object Dates {
    private val Fr = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.FRENCH)
    private val En = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.ENGLISH)

    fun format(epochMs: Long, language: Language, zone: ZoneId = ZoneId.systemDefault()): String {
        val f = if (language == Language.FR) Fr else En
        return f.format(Instant.ofEpochMilli(epochMs).atZone(zone))
    }
}
