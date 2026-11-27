package com.kiwidev.physical.data

/**
 * How a vinyl Disc's wax is patterned. No value (null) means Solid, so existing Discs stay Solid. A Finish is drawn from
 * the Vinyl color and, if it [usesSecondColor], from the Second color, which starts as [defaultSecondColor].
 */
enum class Finish(val defaultSecondColor: VinylColor?) {
    MARBLE(VinylColor.WHITE),
    SPLATTER(VinylColor.WHITE),
    SPLIT(VinylColor.BLACK),
    GALAXY(VinylColor.WHITE),
    GLITTER(null);

    /** Marble, Splatter, Split and Galaxy take a Second color; Glitter is silver flecks on the Vinyl color. */
    val usesSecondColor: Boolean get() = defaultSecondColor != null
}

/** The Finish as shown: only on a vinyl Disc that shows a Vinyl color. A CD keeps its value hidden. */
val Disc.shownFinish: Finish? get() = finish.takeIf { shownVinylColor != null }

/** The Second color as shown: only for a shown Finish that uses one, falling back to that Finish's default. */
val Disc.shownSecondColor: VinylColor?
    get() = shownFinish?.takeIf { it.usesSecondColor }?.let { secondColor ?: it.defaultSecondColor }

/**
 * The Disc after picking [picked] in the form (null = Solid). A Finish that uses a Second color keeps the one already
 * set, or gets its default; going back to Solid keeps the Second color so it comes back with the next Finish.
 */
fun Disc.withFinish(picked: Finish?): Disc = copy(
    finish = picked,
    secondColor = if (picked?.usesSecondColor == true) secondColor ?: picked.defaultSecondColor else secondColor,
)

/** The Disc after the "Vinyle couleur" switch or a color tap: turning it off (null) clears the Finish and Second color too. */
fun Disc.withVinylColor(picked: VinylColor?): Disc =
    if (picked == null) copy(vinylColor = null, finish = null, secondColor = null) else copy(vinylColor = picked)
