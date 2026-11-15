package dev.kiwi.vinyl.data

import org.junit.Assert.assertEquals
import org.junit.Test

class VinylColorTest {
    @Test fun onlyLightWaxGetsDarkGrooves() {
        val light = VinylColor.entries.filter { it.light }.toSet()
        assertEquals(setOf(VinylColor.YELLOW, VinylColor.WHITE, VinylColor.CLEAR), light)
    }
}
