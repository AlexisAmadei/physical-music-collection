package com.kiwidev.physical.ui

import org.junit.Assert.assertEquals
import org.junit.Test

/** How many title lines the back of a Disc card keeps, so the details never reach the barcode and the rating. */
class BackTitleLinesTest {
    @Test fun smallCardKeepsThreeTitleLinesWithNoExtraLine() {
        assertEquals(3, backTitleLines(large = false, hasPrice = false, hasSpeed = false))
    }

    @Test fun smallCardLosesATitleLineForEachExtraLine() {
        assertEquals(2, backTitleLines(large = false, hasPrice = true, hasSpeed = false))
        assertEquals(2, backTitleLines(large = false, hasPrice = false, hasSpeed = true))
        assertEquals(1, backTitleLines(large = false, hasPrice = true, hasSpeed = true))
    }

    @Test fun largeCardKeepsThreeTitleLinesWithoutASpeed() {
        assertEquals(3, backTitleLines(large = true, hasPrice = false, hasSpeed = false))
        assertEquals(3, backTitleLines(large = true, hasPrice = true, hasSpeed = false))
    }

    @Test fun largeCardWithASpeedKeepsTwoTitleLines() {
        assertEquals(2, backTitleLines(large = true, hasPrice = false, hasSpeed = true))
        assertEquals(2, backTitleLines(large = true, hasPrice = true, hasSpeed = true))
    }
}
