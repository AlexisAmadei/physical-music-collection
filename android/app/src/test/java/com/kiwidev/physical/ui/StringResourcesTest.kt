package com.kiwidev.physical.ui

import com.kiwidev.physical.R as AppR
import com.kiwidev.physical.data.Format
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

    /** The Profile card labels: short, to fit the narrow portrait card. Same words on iOS. */
    @Test fun profileCardLabelsInBothLanguages() {
        val en = load("values")
        val fr = load("values-fr")
        val words = mapOf(
            "profile_collection_value" to ("Collection value" to "Valeur"), "profile_vinyls" to ("Vinyls" to "Vinyles"),
            "profile_cds" to ("CDs" to "CD"), "profile_colored" to ("Colored discs" to "Disques colorés"),
            "profile_oldest" to ("Oldest" to "Plus ancien"),
        )
        for ((key, pair) in words) {
            assertEquals(key, pair.first, en.getValue(key).text)
            assertEquals(key, pair.second, fr.getValue(key).text)
        }
        assertEquals("3 without price", String.format(en.getValue("profile_without_price").text, 3))
        assertEquals("3 sans prix", String.format(fr.getValue("profile_without_price").text, 3))
    }

    @Test fun noStringIsBlankInEitherLanguage() {
        for (dir in listOf("values", "values-fr")) {
            val blank = load(dir).values.filter { it.text.isBlank() }.map { it.name }
            assertEquals("$dir has blank strings", emptyList<String>(), blank)
        }
    }

    /** Wording that used to differ from iOS: the same words on both platforms now (see iOS CrossPlatformParityTests). */
    @Test fun englishWordingMatchesIos() {
        val en = load("values")
        assertEquals("Add my first disc", en.getValue("profile_empty_action").text)
        assertEquals("Add the discs you are looking for.", en.getValue("wishlist_empty_hint").text)
        assertEquals("Rating: %1\$d out of 5", en.getValue("rating_of_five").text)
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

    // --- #25: tabs, Home, Collection, Wishlist, disc card, enum labels ---

    /** The resource name behind a generated R.string id, so a label can be checked against the XML. */
    private fun nameOf(id: Int): String =
        AppR.string::class.java.fields.first { it.getInt(null) == id }.name

    @Test fun vinylColorsAreNamedInBothLanguagesWithTheExistingFrenchWordsUnchanged() {
        val en = load("values")
        val fr = load("values-fr")
        val words = mapOf(
            "red" to ("Red" to "Rouge"), "orange" to ("Orange" to "Orange"), "yellow" to ("Yellow" to "Jaune"),
            "green" to ("Green" to "Vert"), "blue" to ("Blue" to "Bleu"), "purple" to ("Purple" to "Violet"),
            "pink" to ("Pink" to "Rose"), "white" to ("White" to "Blanc"), "clear" to ("Clear" to "Transparent"),
        )
        for ((key, pair) in words) {
            assertEquals(key, pair.first, en.getValue("vinyl_color_$key").text)
            assertEquals(key, pair.second, fr.getValue("vinyl_color_$key").text)
        }
    }

    @Test fun formatLabelsAreTranslated() {
        val en = load("values")
        val fr = load("values-fr")
        for ((format, words) in mapOf(Format.CD to ("CD" to "CD"), Format.VINYL to ("Vinyl" to "Vinyle"))) {
            val name = nameOf(format.labelRes)
            assertEquals(name, words.first, en.getValue(name).text)
            assertEquals(name, words.second, fr.getValue(name).text)
        }
    }

    @Test fun speedUnitFollowsTheLanguage() {
        assertEquals("33 rpm", String.format(load("values").getValue("speed_rpm").text, 33))
        assertEquals("45 tr/min", String.format(load("values-fr").getValue("speed_rpm").text, 45))
    }

    @Test fun discCardWordsKeepTheirExistingFrench() {
        val fr = load("values-fr")
        val expected = mapOf(
            "disc_flip" to "Retourner", "disc_untitled" to "Sans titre", "disc_edit" to "Modifier le disque",
            "disc_seen_at" to "Vu à %1\$s", "disc_paid" to "Payé %1\$s", "disc_added_on" to "Ajouté le %1\$s",
            "home_welcome" to "Bienvenue à la maison...", "rating_of_five" to "Note : %1\$d sur 5",
            "rating_none" to "Non noté", "sort_added" to "Date d’ajout", "sort_year" to "Année",
            "tab_search" to "Rechercher", "tab_home" to "Accueil", "wheel_next" to "Disque suivant",
            "wheel_previous" to "Disque précédent",
        )
        for ((key, text) in expected) assertEquals(key, text, fr.getValue(key).text)
    }
}
