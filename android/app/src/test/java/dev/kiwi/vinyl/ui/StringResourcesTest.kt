package dev.kiwi.vinyl.ui

import dev.kiwi.vinyl.R as AppR
import dev.kiwi.vinyl.data.Format
import dev.kiwi.vinyl.data.Speed
import dev.kiwi.vinyl.data.VinylColor
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.w3c.dom.Element

/**
 * Guards the string resources: English is the default (values/), French is the variant (values-fr/).
 * Every translatable entry exists in both, so a missing translation fails here, not on a device.
 */
class StringResourcesTest {
    private class Entry(val name: String, val quantities: Set<String>, val text: String)

    private fun load(dir: String): Map<String, Entry> {
        val file = File("src/main/res/$dir/strings.xml")
        assertTrue("${file.path} is missing", file.exists())
        val root = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file).documentElement
        val out = linkedMapOf<String, Entry>()
        val nodes = root.childNodes
        for (i in 0 until nodes.length) {
            val e = nodes.item(i) as? Element ?: continue
            if (e.getAttribute("translatable") == "false") continue
            val name = e.getAttribute("name")
            val quantities = if (e.tagName == "plurals") {
                val items = e.getElementsByTagName("item")
                (0 until items.length).map { (items.item(it) as Element).getAttribute("quantity") }.toSet()
            } else emptySet()
            out[name] = Entry(name, quantities, e.textContent)
        }
        return out
    }

    @Test fun everyEnglishStringHasAFrenchOneAndTheOtherWayRound() {
        val en = load("values").keys
        val fr = load("values-fr").keys
        assertEquals("only in English", emptySet<String>(), en - fr)
        assertEquals("only in French", emptySet<String>(), fr - en)
    }

    @Test fun discCountsAreRealPluralsWithTheQuantitiesEachLanguageNeeds() {
        val en = load("values")
        val fr = load("values-fr")
        for (name in listOf("disc_count", "discs_without_price")) {
            assertEquals(name, setOf("one", "other"), en.getValue(name).quantities)
            // French: 0 and 1 are "one"; "many" covers millions (CLDR), so lint and ICU agree.
            assertEquals(name, setOf("one", "many", "other"), fr.getValue(name).quantities)
        }
    }

    /** The resource name behind a generated R.string id, so a label can be checked against the XML. */
    private fun nameOf(id: Int): String =
        AppR.string::class.java.fields.first { it.getInt(null) == id }.name

    @Test fun enumLabelsAreTranslatedWithTheExistingFrenchWordsUnchanged() {
        val en = load("values")
        val fr = load("values-fr")
        val expected = mapOf(
            VinylColor.RED to ("Red" to "Rouge"), VinylColor.ORANGE to ("Orange" to "Orange"),
            VinylColor.YELLOW to ("Yellow" to "Jaune"), VinylColor.GREEN to ("Green" to "Vert"),
            VinylColor.BLUE to ("Blue" to "Bleu"), VinylColor.PURPLE to ("Purple" to "Violet"),
            VinylColor.PINK to ("Pink" to "Rose"), VinylColor.WHITE to ("White" to "Blanc"),
            VinylColor.CLEAR to ("Clear" to "Transparent"),
        )
        assertEquals(VinylColor.entries.toSet(), expected.keys)
        for ((color, words) in expected) {
            val name = nameOf(color.labelRes)
            assertEquals(name, words.first, en.getValue(name).text)
            assertEquals(name, words.second, fr.getValue(name).text)
        }
        for ((format, words) in mapOf(Format.CD to ("CD" to "CD"), Format.VINYL to ("Vinyl" to "Vinyle"))) {
            val name = nameOf(format.labelRes)
            assertEquals(name, words.first, en.getValue(name).text)
            assertEquals(name, words.second, fr.getValue(name).text)
        }
    }

    @Test fun speedUnitFollowsTheLanguage() {
        assertEquals(setOf(33, 45), Speed.entries.map { it.rpm }.toSet())
        assertEquals("%1\$d rpm", load("values").getValue("speed_rpm").text)
        assertEquals("%1\$d tr/min", load("values-fr").getValue("speed_rpm").text)
    }
}
