package dev.kiwi.vinyl.data

/** Prices are euro cents (`Long`). Euros only, no conversion. */
object Price {
    private val Valid = Regex("""\d+([.,]\d{1,2})?""")

    /** "12,50", "12.50", "25" → cents. Blank or malformed → null; check [isValid] to tell them apart. */
    fun parse(text: String): Long? {
        val t = text.filterNot { it.isWhitespace() || it == ' ' || it == ' ' }
        if (!Valid.matches(t)) return null
        val (euros, cents) = t.replace(',', '.').split('.').let { it[0] to it.getOrElse(1) { "" } }
        return euros.toLong() * 100 + cents.padEnd(2, '0').toLong()
    }

    /** Blank means "no price", which is allowed. */
    fun isValid(text: String) = text.isBlank() || parse(text) != null

    /**
     * Display in the in-app language, never the device region. Euros only; whole amounts drop the decimals.
     * French "1\u202F240,50\u00A0\u20AC" (narrow no-break space grouping, no-break space before the sign),
     * English "\u20AC1,240.50".
     */
    fun format(cents: Long, language: Language): String {
        val fr = language == Language.FR
        val euros = (cents / 100).toString().reversed().chunked(3).joinToString(if (fr) "\u202F" else ",").reversed()
        val rest = cents % 100
        val number = if (rest == 0L) euros else euros + (if (fr) "," else ".") + rest.toString().padStart(2, '0')
        return if (fr) number + "\u00A0\u20AC" else "\u20AC" + number
    }

    /** What the edit field shows for an existing price: "25", "12,50". */
    fun input(cents: Long?): String = when {
        cents == null -> ""
        cents % 100 == 0L -> (cents / 100).toString()
        else -> "${cents / 100},${(cents % 100).toString().padStart(2, '0')}"
    }
}

/** Sum of the Paid prices of Collection Discs; [unpriced] counts the Collection Discs without one. */
data class CollectionValue(val total: Long, val cd: Long, val vinyl: Long, val unpriced: Int)

fun collectionValue(discs: List<Disc>): CollectionValue {
    val owned = discs.filter { !it.wishlist }
    fun sum(f: Format) = owned.filter { it.format == f }.sumOf { it.paidPrice ?: 0L }
    val cd = sum(Format.CD)
    val vinyl = sum(Format.VINYL)
    return CollectionValue(cd + vinyl, cd, vinyl, owned.count { it.paidPrice == null })
}
