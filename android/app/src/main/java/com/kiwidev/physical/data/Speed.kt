package com.kiwidev.physical.data

/** Speed of a vinyl Disc: the RPM it plays at. Only 33 or 45; no value (null) means not set. */
enum class Speed(val rpm: Int) {
    RPM_33(33),
    RPM_45(45),
}

/** The new Speed after tapping [picked] in the form: tapping the selected one clears it. */
fun Speed?.tapped(picked: Speed): Speed? = if (this == picked) null else picked

/** The Speed as shown: only on vinyl. A CD keeps its value hidden. */
val Disc.shownSpeed: Speed? get() = speed.takeIf { format == Format.VINYL }
