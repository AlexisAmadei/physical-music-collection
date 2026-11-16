package dev.kiwi.vinyl.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VinylColorTest {
    @Test fun onlyLightWaxGetsDarkGrooves() {
        val light = VinylColor.entries.filter { it.light }.toSet()
        assertEquals(setOf(VinylColor.YELLOW, VinylColor.WHITE, VinylColor.CLEAR), light)
    }

    @Test fun colorStickerOnlyOnColoredVinyl() {
        assertTrue(Disc(format = Format.VINYL, vinylColor = VinylColor.RED).hasColorSticker)
        assertFalse(Disc(format = Format.VINYL).hasColorSticker)
        // A CD keeps its hidden Vinyl color, but shows no sticker.
        assertFalse(Disc(format = Format.CD, vinylColor = VinylColor.RED).hasColorSticker)
    }
}
