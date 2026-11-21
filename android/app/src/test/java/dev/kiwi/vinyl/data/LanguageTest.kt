package dev.kiwi.vinyl.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LanguageTest {
    @Test fun noChoiceOnAFrenchDeviceIsFrench() {
        assertEquals(Language.FR, Language.resolve(stored = null, deviceLanguage = "fr"))
    }

    @Test fun noChoiceOnAnyOtherDeviceIsEnglish() {
        assertEquals(Language.EN, Language.resolve(stored = null, deviceLanguage = "en"))
        assertEquals(Language.EN, Language.resolve(stored = null, deviceLanguage = "de"))
        assertEquals(Language.EN, Language.resolve(stored = null, deviceLanguage = ""))
    }

    @Test fun theStoredChoiceWinsOverTheDevice() {
        assertEquals(Language.EN, Language.resolve(stored = Language.EN, deviceLanguage = "fr"))
        assertEquals(Language.FR, Language.resolve(stored = Language.FR, deviceLanguage = "en"))
    }

    @Test fun aStoredTagIsReadBackAndAnythingElseCountsAsNoChoice() {
        assertEquals(Language.FR, Language.fromTag("fr"))
        assertEquals(Language.EN, Language.fromTag("en"))
        assertNull(Language.fromTag(null))
        assertNull(Language.fromTag("de"))
        assertNull(Language.fromTag(""))
    }

    // iOS: AppLanguage.forDevice. Android resolves its resources across the whole locale list too, so the
    // formatters must read the same first supported language the strings do.
    @Test fun theFirstSupportedDeviceLanguageWins() {
        assertEquals(Language.FR, Language.forDevice(listOf("de", "fr")))
        assertEquals(Language.EN, Language.forDevice(listOf("de", "en", "fr")))
        assertEquals(Language.FR, Language.forDevice(listOf("fr", "en")))
    }

    @Test fun aDeviceWithNeitherLanguageIsEnglish() {
        assertEquals(Language.EN, Language.forDevice(listOf("de", "es")))
        assertEquals(Language.EN, Language.forDevice(emptyList()))
    }

    @Test fun eachLanguageIsStoredByItsTag() {
        assertEquals("en", Language.EN.tag)
        assertEquals("fr", Language.FR.tag)
    }
}
