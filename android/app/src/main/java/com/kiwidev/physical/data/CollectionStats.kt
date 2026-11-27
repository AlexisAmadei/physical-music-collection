package com.kiwidev.physical.data

/**
 * What the Profile card shows, over the Collection Discs only (Wishlist Discs never count).
 * [colored]: vinyl Discs with a Vinyl color (Clear included); a CD keeping a hidden one is not counted.
 * [oldestYear]: among the Discs that have a year, null when none has. [value] and [unpriced]: see [collectionValue].
 */
data class CollectionStats(val vinyls: Int, val cds: Int, val colored: Int, val oldestYear: Int?, val value: Long, val unpriced: Int)

fun collectionStats(discs: List<Disc>): CollectionStats {
    val owned = discs.filter { !it.wishlist }
    val value = collectionValue(owned)
    return CollectionStats(
        vinyls = owned.count { it.format == Format.VINYL },
        cds = owned.count { it.format == Format.CD },
        colored = owned.count { it.format == Format.VINYL && it.vinylColor != null },
        oldestYear = owned.mapNotNull { it.year }.minOrNull(),
        value = value.total,
        unpriced = value.unpriced,
    )
}
