package dev.kiwi.vinyl.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.max
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.VinylColor
import dev.kiwi.vinyl.data.shownVinylColor

private val StickerRim = Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.9f), Color(0xFF8A9097).copy(alpha = 0.8f)))

/**
 * Color sticker of [d], top-right of the cover it sits on (a Box filling that cover), if it has one.
 * About 22 % of the cover width, never under 14 dp. Decorative: the cover's label says it.
 */
@Composable
fun BoxScope.ColorStickerOf(d: Disc) {
    val color = d.shownVinylColor ?: return
    BoxWithConstraints(Modifier.matchParentSize()) {
        ColorSticker(color, Modifier.align(Alignment.TopEnd).padding(max(3.dp, maxWidth * 0.05f)).size(max(14.dp, maxWidth * 0.22f)))
    }
}

/** Round holo silver sticker, a dot of the wax color in the middle. The sheen follows the phone tilt. */
@Composable
fun ColorSticker(color: VinylColor, modifier: Modifier = Modifier) {
    val light = rememberHoloLight()
    Box(
        modifier
            .shadow(1.5.dp, CircleShape, ambientColor = Color.Black.copy(alpha = 0.35f), spotColor = Color.Black.copy(alpha = 0.35f))
            .clip(CircleShape)
            .drawBehind { drawSilver(light.value) }
            .border(0.5.dp, StickerRim, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .fillMaxSize(0.4f)
                .clip(CircleShape)
                .background(Color(color.argb))
                // Light wax (white, clear...) needs an edge to read on silver.
                .then(if (color.light) Modifier.border(0.5.dp, Color.Black.copy(alpha = 0.3f), CircleShape) else Modifier),
        )
    }
}
