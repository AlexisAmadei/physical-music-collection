package com.kiwidev.physical.data

import kotlin.math.pow

/**
 * A wax color of a vinyl Disc: its Vinyl color, or the Second color of a Finish. No Vinyl color (null) means black wax;
 * [BLACK] exists only to be a Second color.
 */
enum class VinylColor(val argb: Long) {
    RED(0xFFC8242B),
    ORANGE(0xFFE8731E),
    YELLOW(0xFFF2C94C),
    GREEN(0xFF2E8B57),
    BLUE(0xFF2B5BA8),
    PURPLE(0xFF6B3FA0),
    PINK(0xFFE0609A),
    WHITE(0xFFF4F2EE),
    /** See-through: drawn half transparent. */
    CLEAR(0x8CE6ECF0),
    GOLD(0xFFC9A227),
    SILVER(0xFFB8BCC2),
    GREY(0xFF7D8085),
    BROWN(0xFF6B4A32),
    TEAL(0xFF1F8A8A),
    BONE(0xFFE9E1CC),
    /** Only as a Second color: plain black wax is "no Vinyl color". Same near black as the black wax. */
    BLACK(0xFF121212);

    companion object {
        /** The colors offered as the Vinyl color: all but [BLACK]. Order is the order in the form. */
        val firstChoices: List<VinylColor> = entries - BLACK

        /** The colors offered as the Second color: all but [CLEAR]. */
        val secondChoices: List<VinylColor> = entries - CLEAR
    }

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
