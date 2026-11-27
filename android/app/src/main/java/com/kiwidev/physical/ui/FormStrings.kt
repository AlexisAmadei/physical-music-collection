package com.kiwidev.physical.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.kiwidev.physical.R as AppR
import com.kiwidev.physical.data.Finish
import com.kiwidev.physical.data.Format
import com.kiwidev.physical.data.VinylColor
import com.kiwidev.physical.data.upperCase

/** The Vinyl color named in the active language. */
@Composable
fun VinylColor.displayName(): String = stringResource(
    when (this) {
        VinylColor.RED -> AppR.string.vinyl_color_red
        VinylColor.ORANGE -> AppR.string.vinyl_color_orange
        VinylColor.YELLOW -> AppR.string.vinyl_color_yellow
        VinylColor.GREEN -> AppR.string.vinyl_color_green
        VinylColor.BLUE -> AppR.string.vinyl_color_blue
        VinylColor.PURPLE -> AppR.string.vinyl_color_purple
        VinylColor.PINK -> AppR.string.vinyl_color_pink
        VinylColor.WHITE -> AppR.string.vinyl_color_white
        VinylColor.CLEAR -> AppR.string.vinyl_color_clear
        VinylColor.GOLD -> AppR.string.vinyl_color_gold
        VinylColor.SILVER -> AppR.string.vinyl_color_silver
        VinylColor.GREY -> AppR.string.vinyl_color_grey
        VinylColor.BROWN -> AppR.string.vinyl_color_brown
        VinylColor.TEAL -> AppR.string.vinyl_color_teal
        VinylColor.BONE -> AppR.string.vinyl_color_bone
        VinylColor.BLACK -> AppR.string.vinyl_color_black
    },
)

/** The Finish named in the active language; null is Solid. */
@Composable
fun Finish?.displayName(): String = stringResource(
    when (this) {
        null -> AppR.string.finish_solid
        Finish.MARBLE -> AppR.string.finish_marble
        Finish.SPLATTER -> AppR.string.finish_splatter
        Finish.SPLIT -> AppR.string.finish_split
        Finish.GALAXY -> AppR.string.finish_galaxy
        Finish.GLITTER -> AppR.string.finish_glitter
    },
)

/** The Format label as an uppercase tag ("CD", "VINYL" / "VINYLE"), in the active language. */
@Composable
fun Format.tag(): String = stringResource(labelRes).upperCase()
