package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Test

/** What the Profile card shows. iOS: CollectionStatsTests, same cases. */
class CollectionStatsTest {
    @Test fun countsFormatsColoredDiscsAndTheOldestYear() {
        val s = collectionStats(listOf(
            Disc(format = Format.VINYL, year = 1994, vinylColor = VinylColor.RED, paidPrice = 2500),
            Disc(format = Format.VINYL, year = 1971),
            Disc(format = Format.VINYL, vinylColor = VinylColor.CLEAR),
            Disc(format = Format.CD, year = 1988, paidPrice = 1000),
        ))
        assertEquals(CollectionStats(vinyls = 3, cds = 1, colored = 2, oldestYear = 1971, value = 3500, unpriced = 2), s)
    }

    @Test fun aCdKeepingAHiddenVinylColorIsNotColored() {
        assertEquals(0, collectionStats(listOf(Disc(format = Format.CD, vinylColor = VinylColor.BLUE))).colored)
    }

    @Test fun discsWithoutAYearAreIgnoredAndNoYearAtAllIsNull() {
        assertEquals(null, collectionStats(listOf(Disc(), Disc(format = Format.CD))).oldestYear)
        assertEquals(2001, collectionStats(listOf(Disc(), Disc(year = 2001))).oldestYear)
    }

    @Test fun wishlistDiscsNeverCount() {
        val s = collectionStats(listOf(Disc(wishlist = true, year = 1950, vinylColor = VinylColor.PINK, paidPrice = 900)))
        assertEquals(CollectionStats(vinyls = 0, cds = 0, colored = 0, oldestYear = null, value = 0, unpriced = 0), s)
    }

    @Test fun anEmptyCollectionIsAllZero() {
        assertEquals(CollectionStats(vinyls = 0, cds = 0, colored = 0, oldestYear = null, value = 0, unpriced = 0), collectionStats(emptyList()))
    }
}
