package dev.kiwi.vinyl.ui

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
    private class Entry(val name: String, val quantities: Set<String>)

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
            out[name] = Entry(name, quantities)
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
}
