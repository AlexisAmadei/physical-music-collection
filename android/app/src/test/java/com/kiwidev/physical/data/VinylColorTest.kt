package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VinylColorTest {
    @Test fun onlyLightWaxGetsDarkGrooves() {
        val light = VinylColor.entries.filter { it.light }.toSet()
        assertEquals(setOf(VinylColor.YELLOW, VinylColor.WHITE, VinylColor.CLEAR, VinylColor.SILVER, VinylColor.BONE), light)
    }

    @Test fun newColorsComeAfterTodaysNineSoStoredOrderIsStable() {
        assertEquals(
            listOf("RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE", "PINK", "WHITE", "CLEAR", "GOLD", "SILVER", "GREY", "BROWN", "TEAL", "BONE", "BLACK"),
            VinylColor.entries.map { it.name },
        )
    }

    @Test fun blackIsOnlyASecondColorAndClearIsOnlyAVinylColor() {
        assertFalse(VinylColor.BLACK in VinylColor.firstChoices)
        assertTrue(VinylColor.BLACK in VinylColor.secondChoices)
        assertTrue(VinylColor.CLEAR in VinylColor.firstChoices)
        assertFalse(VinylColor.CLEAR in VinylColor.secondChoices)
        assertEquals(15, VinylColor.firstChoices.size)
        assertEquals(15, VinylColor.secondChoices.size)
    }

    @Test fun colorBandOnlyOnColoredVinyl() {
        assertTrue(Disc(format = Format.VINYL, vinylColor = VinylColor.RED).hasColorBand)
        assertFalse(Disc(format = Format.VINYL).hasColorBand)
        // A CD keeps its hidden Vinyl color, but shows no band.
        assertFalse(Disc(format = Format.CD, vinylColor = VinylColor.RED).hasColorBand)
    }
}
