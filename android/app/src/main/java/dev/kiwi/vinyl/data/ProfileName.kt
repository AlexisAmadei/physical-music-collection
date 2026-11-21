package dev.kiwi.vinyl.data

/** The name the user types for the Profile card. Blank = unset. */
object ProfileName {
    const val MAX = 24

    fun clean(raw: String): String = raw.trim().take(MAX).trim()
}
