package dev.kiwi.vinyl.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PriceTest {
    @Test fun parsesCommaDotAndWhole() {
        assertEquals(1250L, Price.parse("12,50"))
        assertEquals(1250L, Price.parse("12.50"))
        assertEquals(1250L, Price.parse("12,5"))
        assertEquals(2500L, Price.parse("25"))
        assertEquals(124000L, Price.parse("1 240"))
    }

    @Test fun blankIsNoPriceAndValid() {
        assertNull(Price.parse("  "))
        assertTrue(Price.isValid(""))
    }

    @Test fun rejectsMalformed() {
        listOf("abc", "12,", "12,505", "-3", "1,2,3", "12€").forEach {
            assertNull(it, Price.parse(it))
            assertFalse(it, Price.isValid(it))
        }
    }

    @Test fun formatsFrench() {
        assertEquals("25 €", Price.format(2500, Language.FR))
        assertEquals("12,50 €", Price.format(1250, Language.FR))
        assertEquals("0,05 €", Price.format(5, Language.FR))
        assertEquals("1 240 €", Price.format(124000, Language.FR))
        assertEquals("0 €", Price.format(0, Language.FR))
    }

    @Test fun formatsFrenchBytesWithNarrowNoBreakGroupingAndNoBreakBeforeEuro() {
        assertEquals("1 240,50 €", Price.format(124050, Language.FR))
        assertEquals("1 234 567 €", Price.format(123456700, Language.FR))
    }

    @Test fun formatsEnglish() {
        assertEquals("€25", Price.format(2500, Language.EN))
        assertEquals("€12.50", Price.format(1250, Language.EN))
        assertEquals("€0.05", Price.format(5, Language.EN))
        assertEquals("€1,240", Price.format(124000, Language.EN))
        assertEquals("€1,240.50", Price.format(124050, Language.EN))
        assertEquals("€1,234,567", Price.format(123456700, Language.EN))
        assertEquals("€0", Price.format(0, Language.EN))
    }

    @Test fun formatFollowsTheLanguageNotTheDeviceRegion() {
        val saved = java.util.Locale.getDefault()
        try {
            java.util.Locale.setDefault(java.util.Locale.GERMANY)
            assertEquals("€1,240.50", Price.format(124050, Language.EN))
            assertEquals("1 240,50 €", Price.format(124050, Language.FR))
        } finally {
            java.util.Locale.setDefault(saved)
        }
    }

    @Test fun inputRoundTrips() {
        listOf(2500L, 1250L, 5L, 124000L).forEach { assertEquals(it, Price.parse(Price.input(it))) }
        assertEquals("", Price.input(null))
    }

    @Test fun collectionValueSkipsWishlistAndCountsUnpriced() {
        val v = collectionValue(listOf(
            Disc(format = Format.CD, paidPrice = 1000),
            Disc(format = Format.VINYL, paidPrice = 2550),
            Disc(format = Format.VINYL),
            Disc(format = Format.VINYL, wishlist = true, paidPrice = 9999, seenPrice = 3000),
        ))
        assertEquals(CollectionValue(total = 3550, cd = 1000, vinyl = 2550, unpriced = 1), v)
    }
}
