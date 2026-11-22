package com.kiwidev.physical.data

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class CasingTest {
    // Chrome text is cased the same way whatever the device region: a Turkish device must not turn
    // "vinyl" into a dotted capital I.
    @Test fun caseIgnoresTheDeviceRegion() {
        val saved = Locale.getDefault()
        try {
            Locale.setDefault(Locale.forLanguageTag("tr-TR"))
            assertEquals("VINYL", "vinyl".upperCase())
            assertEquals("INDIGO", "indigo".upperCase())
            assertEquals("indigo", "INDIGO".lowerCase())
            assertEquals("ÉTÉ", "été".upperCase())
        } finally {
            Locale.setDefault(saved)
        }
    }
}
