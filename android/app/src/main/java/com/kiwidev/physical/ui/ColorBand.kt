package com.kiwidev.physical.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.unit.dp
import com.kiwidev.physical.data.Disc
import com.kiwidev.physical.data.VinylColor
import com.kiwidev.physical.data.shownVinylColor

/** Band thickness as a share of the cover width, never under [BandMin]. */
private const val BandShare = 0.11f
private val BandMin = 8.dp

/** Length of the cut corner along each cover edge, in band thicknesses. */
private const val BandLeg = 4f

/** Clear wax is a frosted band, mostly opaque so it still reads over the cover art. */
private const val ClearBandAlpha = 0.75f

/** Half a band thickness, measured along a cover edge: thickness / sqrt(2). */
private const val HalfThicknessOnEdge = 0.70710677f

/**
 * Color band of [d], across the top-right corner of the cover it sits on (a Box filling that cover), if it has one.
 * Decorative: the cover's label says the Vinyl color.
 */
@Composable
fun BoxScope.ColorBandOf(d: Disc) {
    val color = d.shownVinylColor ?: return
    ColorBand(color, Modifier.matchParentSize())
}

/** Flat diagonal band of the wax color cutting the top-right corner. Fills the cover it is drawn on. */
@Composable
fun ColorBand(color: VinylColor, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val thickness = maxOf(BandMin.toPx(), w * BandShare)
        val centre = w - BandLeg * thickness
        val half = thickness * HalfThicknessOnEdge
        // The band's two long edges run from the top edge to the right edge of the cover.
        val band = Path().apply {
            moveTo(centre - half, 0f)
            lineTo(centre + half, 0f)
            lineTo(w, w - (centre + half))
            lineTo(w, w - (centre - half))
            close()
        }
        // Small drop shadow, kept off the band itself so frosted wax does not darken.
        clipPath(band, ClipOp.Difference) {
            translate(top = 0.75.dp.toPx()) { drawPath(band, Color.Black.copy(alpha = 0.3f)) }
        }
        val wax = Color(color.argb)
        drawPath(band, if (color == VinylColor.CLEAR) wax.copy(alpha = ClearBandAlpha) else wax)
        // Light wax (white, clear...) needs an edge to read on the cover.
        if (color.light) drawPath(band, Color.Black.copy(alpha = 0.3f), style = Stroke(0.5.dp.toPx()))
    }
}
