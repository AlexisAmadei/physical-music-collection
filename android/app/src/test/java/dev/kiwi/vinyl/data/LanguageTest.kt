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

    @Test fun eachLanguageIsStoredByItsTag() {
        assertEquals("en", Language.EN.tag)
        assertEquals("fr", Language.FR.tag)
    }
}
