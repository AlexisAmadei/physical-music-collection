package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LanguageTest {
    // Language.reconcile(stored pick, the app's own locale, the device languages). The app locale is
    // the one Android renders with, and on API 33+ the one the system "App languages" screen edits.

    @Test fun noPickAndNoAppLocaleFollowsTheDeviceWithEnglishFallback() {
        assertEquals(Language.FR, reconcile(stored = null, device = listOf("fr")).effective)
        assertEquals(Language.EN, reconcile(stored = null, device = listOf("en")).effective)
        assertEquals(Language.EN, reconcile(stored = null, device = listOf("de")).effective)
        assertEquals(Language.EN, reconcile(stored = null, device = emptyList()).effective)
        assertEquals(Language.FR, reconcile(stored = null, device = listOf("de", "fr")).effective)
    }

    @Test fun anExplicitPickWinsOverTheDeviceWhenTheSystemHoldsNoLocale() {
        // API < 33: appcompat does not persist the locale, so the stored pick is put back in force.
        val r = reconcile(stored = Language.EN, device = listOf("fr"), systemKeepsAppLocale = false)
        assertEquals(Language.EN, r.effective)
        assertEquals(Language.EN, r.stored)
        assertEquals(Language.EN, r.apply)
    }

    @Test fun noPickAndNoAppLocaleAppliesNothing() {
        val r = reconcile(stored = null, device = listOf("fr"), systemKeepsAppLocale = false)
        assertNull(r.stored)
        assertNull(r.apply)
    }

    @Test fun theAppLocaleIsWhatIsRenderedAndNothingIsReappliedWhenItMatchesThePick() {
        val r = reconcile(stored = Language.EN, appLocales = listOf("en"), device = listOf("fr"))
        assertEquals(Language.EN, r.effective)
        assertEquals(Language.EN, r.stored)
        assertNull(r.apply)
    }

    @Test fun aLaterSystemPickBeatsAStaleStoredPickAndIsSynced() {
        // Picked English in the app, then Francais in the system per-app language settings.
        val r = reconcile(stored = Language.EN, appLocales = listOf("fr"), device = listOf("en"))
        assertEquals(Language.FR, r.effective)
        assertEquals(Language.FR, r.stored)
        assertNull(r.apply)
    }

    @Test fun aSystemPickWithNoStoredPickIsSynced() {
        val r = reconcile(stored = null, appLocales = listOf("fr"), device = listOf("en"))
        assertEquals(Language.FR, r.effective)
        assertEquals(Language.FR, r.stored)
    }

    @Test fun theFirstSupportedAppLocaleCounts() {
        val r = reconcile(stored = null, appLocales = listOf("de", "fr"), device = listOf("en"))
        assertEquals(Language.FR, r.effective)
    }

    @Test fun resettingTheSystemPickToDefaultFollowsTheDeviceAgain() {
        // API 33+: the system keeps the app locale, so none means the user cleared it.
        val r = reconcile(stored = Language.EN, device = listOf("fr"), systemKeepsAppLocale = true)
        assertEquals(Language.FR, r.effective)
        assertNull(r.stored)
        assertNull(r.apply)
    }

    private fun reconcile(
        stored: Language?, appLocales: List<String> = emptyList(), device: List<String>, systemKeepsAppLocale: Boolean = true,
    ) = Language.reconcile(stored, appLocales, device, systemKeepsAppLocale)

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
