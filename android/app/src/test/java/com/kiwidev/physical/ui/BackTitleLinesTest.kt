package com.kiwidev.physical.ui

import org.junit.Assert.assertEquals
import org.junit.Test

/** How many title lines the back of a Disc card keeps, so the details never reach the barcode and the rating. */
class BackTitleLinesTest {
    @Test fun smallCardKeepsThreeTitleLinesWithNoExtraLine() {
        assertEquals(3, backTitleLines(large = false, hasPrice = false, hasSpecs = false))
    }

    @Test fun smallCardLosesATitleLineForEachExtraLine() {
        assertEquals(2, backTitleLines(large = false, hasPrice = true, hasSpecs = false))
        assertEquals(2, backTitleLines(large = false, hasPrice = false, hasSpecs = true))
        assertEquals(1, backTitleLines(large = false, hasPrice = true, hasSpecs = true))
    }

    @Test fun largeCardKeepsThreeTitleLinesWithoutASpecsLine() {
        assertEquals(3, backTitleLines(large = true, hasPrice = false, hasSpecs = false))
        assertEquals(3, backTitleLines(large = true, hasPrice = true, hasSpecs = false))
    }

    @Test fun largeCardWithASpecsLineKeepsTwoTitleLines() {
        assertEquals(2, backTitleLines(large = true, hasPrice = false, hasSpecs = true))
        assertEquals(2, backTitleLines(large = true, hasPrice = true, hasSpecs = true))
    }
}
