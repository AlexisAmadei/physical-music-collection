package com.kiwidev.physical.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.kiwidev.physical.R as AppR
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
    },
)

/** The Format label as an uppercase tag ("CD", "VINYL" / "VINYLE"), in the active language. */
@Composable
fun Format.tag(): String = stringResource(labelRes).upperCase()
