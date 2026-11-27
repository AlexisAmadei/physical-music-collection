package com.kiwidev.physical.ui

import android.graphics.Bitmap
import android.util.LruCache
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.kiwidev.physical.data.Droplet
import com.kiwidev.physical.data.Finish
import com.kiwidev.physical.data.VinylColor
import com.kiwidev.physical.data.WaxPattern
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

/** Near black: the wax of a Disc with no Vinyl color. */
private val BlackWax = Color(0xFF121212)

/** Wax bitmaps (Marble, Galaxy) already built, so reopening a sleeve or scrolling back does not compute them again. */
private object MarbleCache {
    val cache = LruCache<String, ImageBitmap>(12)
}

/**
 * The bitmap under a Finish that has one (Marble, Galaxy), built off the main thread; null until it is ready, and
 * for every other Finish. [n] is its side in pixels.
 */
@Composable
fun rememberWaxBitmap(finish: Finish?, base: VinylColor?, second: VinylColor?, seed: Long, n: Int = WaxPattern.MARBLE_SIZE): ImageBitmap? {
    if ((finish != Finish.MARBLE && finish != Finish.GALAXY) || base == null || second == null) return null
    val key = "$seed|$finish|$base|$second|$n"
    val bitmap by produceState(MarbleCache.cache.get(key), key) {
        if (value == null) {
            value = withContext(Dispatchers.Default) {
                val pixels = checkNotNull(WaxPattern.bitmap(finish, seed, base, second, n))
                Bitmap.createBitmap(pixels, n, n, Bitmap.Config.ARGB_8888).asImageBitmap()
            }.also { MarbleCache.cache.put(key, it) }
        }
    }
    return bitmap
}

/**
 * The wax of a vinyl Disc, filling this scope's circle: its Vinyl color ([base], null = black) and its Finish. Marble and
 * Galaxy draw [bitmap] (the wax color alone until it is ready); Splatter, Split, the Galaxy stars and Glitter flecks are
 * drawn from [WaxPattern]. The Color band is not part of this: it stays flat.
 */
fun DrawScope.drawWax(base: VinylColor?, finish: Finish?, second: VinylColor?, seed: Long, bitmap: ImageBitmap?) {
    val baseColor = base?.let { Color(it.argb) } ?: BlackWax
    val radius = size.minDimension / 2
    val centre = Offset(size.width / 2, size.height / 2)
    val disc = Path().apply { addOval(Rect(centre, radius)) }
    val secondColor = second?.let { Color(it.argb) } ?: Color.White

    fun DrawScope.drops(drops: List<Droplet>, colorOf: (Droplet) -> Color) {
        for (d in drops) {
            val color = colorOf(d)
            val cx = centre.x + (d.x * radius).toFloat()
            val cy = centre.y + (d.y * radius).toFloat()
            val rx = (d.rx * radius).toFloat()
            val ry = (d.ry * radius).toFloat()
            rotate(Math.toDegrees(d.rot).toFloat(), Offset(cx, cy)) {
                drawOval(color.copy(alpha = d.alpha.toFloat()), Offset(cx - rx, cy - ry), Size(2 * rx, 2 * ry))
            }
        }
    }

    if ((finish == Finish.MARBLE || finish == Finish.GALAXY) && bitmap != null) {
        clipPath(disc) {
            drawImage(bitmap, dstOffset = IntOffset.Zero, dstSize = IntSize(size.width.roundToInt(), size.height.roundToInt()), filterQuality = FilterQuality.High)
        }
    } else {
        drawCircle(baseColor, radius, centre)
    }
    when (finish) {
        null, Finish.MARBLE -> Unit
        Finish.SPLATTER -> clipPath(disc) { drops(WaxPattern.splatter(seed)) { secondColor } }
        Finish.SPLIT -> clipPath(disc) {
            rotate(Math.toDegrees(WaxPattern.splitAngle(seed)).toFloat(), centre) {
                drawRect(secondColor, Offset(centre.x, centre.y - radius), Size(radius, 2 * radius))
            }
        }
        Finish.GALAXY -> clipPath(disc) {
            val stars = WaxPattern.stars(seed)
            drops(stars.dots) { Color.White }
            for (g in stars.glows) {
                val c = Offset(centre.x + (g.x * radius).toFloat(), centre.y + (g.y * radius).toFloat())
                val r = (g.rx * radius).toFloat()
                drawCircle(
                    Brush.radialGradient(0f to Color.White.copy(alpha = 0.95f), 0.25f to Color.White.copy(alpha = 0.55f), 1f to Color.Transparent, center = c, radius = r),
                    r, c,
                )
            }
        }
        Finish.GLITTER -> clipPath(disc) {
            val tint = base ?: VinylColor.WHITE
            drops(WaxPattern.flecks(seed)) { Color(WaxPattern.fleckColor(tint, it.tone)) }
        }
    }
}
