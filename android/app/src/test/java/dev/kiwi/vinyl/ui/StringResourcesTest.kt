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
    private class Entry(val name: String, val quantities: Set<String>, val text: String = "")

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

    /** Search, Scan and the add/edit form (#26): all user-visible copy lives in resources, in both languages. */
    private val searchScanFormKeys = listOf(
        "search_not_found", "search_hint", "search_my_discs", "search_catalog", "search_searching", "search_add_manually",
        "scan_enter_manually", "scan_camera_needed", "scan_looking_up",
        "form_add_title", "form_edit_title", "form_title", "form_artist", "form_year", "form_barcode", "form_comment",
        "form_vinyl_color", "form_speed", "speed_rpm", "form_rate", "form_in_wishlist", "form_seen_price", "form_paid_price",
        "form_price_example", "form_save", "form_delete",
        "vinyl_color_red", "vinyl_color_orange", "vinyl_color_yellow", "vinyl_color_green", "vinyl_color_blue",
        "vinyl_color_purple", "vinyl_color_pink", "vinyl_color_white", "vinyl_color_clear",
    )

    @Test fun searchScanAndFormStringsExistInBothLanguages() {
        for (dir in listOf("values", "values-fr")) {
            val keys = load(dir).keys
            assertEquals("$dir is missing", emptyList<String>(), searchScanFormKeys.filter { it !in keys })
        }
    }

    private val specifier = Regex("%(\\d+\\$)?[sd]")

    @Test fun interpolationPlaceholdersAreTheSameInBothLanguages() {
        val en = load("values")
        val fr = load("values-fr")
        // Plain strings only: plurals legitimately differ in item count between languages.
        for (name in en.keys.intersect(fr.keys).filter { en.getValue(it).quantities.isEmpty() }) {
            assertEquals(name, specifier.findAll(en.getValue(name).text).map { it.value }.toList(),
                specifier.findAll(fr.getValue(name).text).map { it.value }.toList())
        }
    }

    @Test fun interpolatedMessagesFormatCorrectlyInBothLanguages() {
        for (dir in listOf("values", "values-fr")) {
            val res = load(dir)
            for ((name, arg) in listOf("search_not_found" to "3700187660335", "scan_looking_up" to "3700187660335")) {
                val out = String.format(res.getValue(name).text, arg)
                assertTrue("$dir/$name: $out", arg in out && "%" !in out)
            }
            for ((name, arg) in listOf("form_rate" to 4, "speed_rpm" to 33)) {
                val out = String.format(res.getValue(name).text, arg)
                assertTrue("$dir/$name: $out", arg.toString() in out && "%" !in out)
            }
        }
    }
}
