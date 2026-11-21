package dev.kiwi.vinyl.ui

import android.content.res.Configuration
import androidx.test.platform.app.InstrumentationRegistry
import dev.kiwi.vinyl.R
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

/** Disc counts follow each language's real plural rules, through the same resources the screens use. */
class PluralsTest {
    private fun counts(language: String, plural: Int): List<String> {
        val base = InstrumentationRegistry.getInstrumentation().targetContext
        val config = Configuration(base.resources.configuration).apply { setLocale(Locale.forLanguageTag(language)) }
        val res = base.createConfigurationContext(config).resources
        return listOf(0, 1, 2, 12).map { res.getQuantityString(plural, it, it) }
    }

    @Test fun frenchZeroAndOneAreSingular() {
        assertEquals(listOf("0 disque", "1 disque", "2 disques", "12 disques"), counts("fr", R.plurals.disc_count))
        assertEquals(
            listOf("0 disque sans prix", "1 disque sans prix", "2 disques sans prix", "12 disques sans prix"),
            counts("fr", R.plurals.discs_without_price),
        )
    }

    @Test fun englishZeroIsPlural() {
        assertEquals(listOf("0 discs", "1 disc", "2 discs", "12 discs"), counts("en", R.plurals.disc_count))
        assertEquals(
            listOf("0 discs without a price", "1 disc without a price", "2 discs without a price", "12 discs without a price"),
            counts("en", R.plurals.discs_without_price),
        )
    }
}
