package com.kiwidev.physical.data

import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class DatesTest {
    private val utc = ZoneId.of("UTC")
    private fun ms(y: Int, m: Int, d: Int) = ZonedDateTime.of(y, m, d, 12, 0, 0, 0, utc).toInstant().toEpochMilli()

    @Test fun formatsFrench() {
        assertEquals("3 nov. 2024", Dates.format(ms(2024, 11, 3), Language.FR, utc))
        assertEquals("9 mars 2025", Dates.format(ms(2025, 3, 9), Language.FR, utc))
    }

    @Test fun formatsEnglish() {
        assertEquals("Nov 3, 2024", Dates.format(ms(2024, 11, 3), Language.EN, utc))
        assertEquals("Mar 9, 2025", Dates.format(ms(2025, 3, 9), Language.EN, utc))
    }

    @Test fun followsTheLanguageNotTheDeviceRegion() {
        val saved = Locale.getDefault()
        try {
            Locale.setDefault(Locale.GERMANY)
            assertEquals("Nov 3, 2024", Dates.format(ms(2024, 11, 3), Language.EN, utc))
            assertEquals("3 nov. 2024", Dates.format(ms(2024, 11, 3), Language.FR, utc))
        } finally {
            Locale.setDefault(saved)
        }
    }
}
