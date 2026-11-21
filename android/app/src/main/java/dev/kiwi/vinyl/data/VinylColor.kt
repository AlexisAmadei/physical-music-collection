package dev.kiwi.vinyl.data

import androidx.annotation.StringRes
import dev.kiwi.vinyl.R
import kotlin.math.pow

/** Vinyl color of a vinyl Disc's wax. No value (null) means black. Solid colors only. */
enum class VinylColor(val argb: Long, @StringRes val labelRes: Int) {
    RED(0xFFC8242B, R.string.vinyl_color_red),
    ORANGE(0xFFE8731E, R.string.vinyl_color_orange),
    YELLOW(0xFFF2C94C, R.string.vinyl_color_yellow),
    GREEN(0xFF2E8B57, R.string.vinyl_color_green),
    BLUE(0xFF2B5BA8, R.string.vinyl_color_blue),
    PURPLE(0xFF6B3FA0, R.string.vinyl_color_purple),
    PINK(0xFFE0609A, R.string.vinyl_color_pink),
    WHITE(0xFFF4F2EE, R.string.vinyl_color_white),
    /** See-through: drawn half transparent. */
    CLEAR(0x8CE6ECF0, R.string.vinyl_color_clear);

    /** Light wax needs dark grooves, or they vanish. */
    val light: Boolean get() = luminance() > 0.4

    private fun luminance(): Double {
        fun lin(shift: Int): Double {
            val c = ((argb shr shift) and 0xFF) / 255.0
            return if (c <= 0.04045) c / 12.92 else ((c + 0.055) / 1.055).pow(2.4)
        }
        return 0.2126 * lin(16) + 0.7152 * lin(8) + 0.0722 * lin(0)
    }
}

/** The Vinyl color as shown: only on vinyl. A CD keeps its value hidden. */
val Disc.shownVinylColor: VinylColor? get() = vinylColor.takeIf { format == Format.VINYL }

/** Shows the Color band on its cover. */
val Disc.hasColorBand: Boolean get() = shownVinylColor != null
