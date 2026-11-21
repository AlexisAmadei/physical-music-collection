package dev.kiwi.vinyl.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.CacheDrawScope
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.toRect
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import dev.kiwi.vinyl.R as AppR
import dev.kiwi.vinyl.data.Price
import kotlin.math.exp
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.random.Random

private val CardShape = RoundedCornerShape(18.dp)
private val CardInk = Color(0xFF33363B)
private val CardMuted = Color(0xFF5F646B)
/** Light edge under the letters: reads as engraved in the metal. */
private val Engraved = Shadow(Color.White.copy(alpha = 0.8f), Offset(0f, 2f), 0f)
private val Rim = Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.9f), Color(0xFF9AA0A7).copy(alpha = 0.6f)))
private val Base = listOf(Color(0xFFC6CACF), Color(0xFFEEF0F2), Color(0xFFB6BBC1), Color(0xFFE2E5E8), Color(0xFFC2C6CB))
private val Rainbow = listOf(
    Color(0xFFFF9AA2), Color(0xFFFFD58A), Color(0xFFB5F0A0), Color(0xFF9EE6F0), Color(0xFFA9B4FF), Color(0xFFE0A8FF),
)

private const val MAX_DEG = 10f
private const val INTRO_NS = 1_400_000_000L
/** The intro starts lit from the top right, then settles. */
private val IntroStart = Offset(0.62f, -0.55f)
/** Reduced motion: no tilt, light fixed here. */
internal val StillLight = Offset(0.35f, -0.3f)

/**
 * The Profile card: round-brushed silver, like the grooves of a record. Tilts with the phone,
 * and with the finger while it touches. The reflection turns with the tilt; a slight rainbow
 * shows only where the light hits.
 */
@Composable
fun ProfileCard(name: String, value: Long, discs: Int, onEditName: () -> Unit, modifier: Modifier = Modifier) {
    val reduced = rememberReducedMotion()
    val phone = rememberHoloTilt()
    var finger by remember { mutableStateOf<Tilt?>(null) }
    // Shown tilt, x / y in -1..1 (see Tilt). Read only in layer and draw: no recomposition per frame.
    val shown = remember { mutableStateOf(if (reduced) StillLight else IntroStart) }
    if (!reduced) LaunchedEffect(Unit) {
        val start = withFrameNanos { it }
        var last = start
        while (true) {
            val now = withFrameNanos { it }
            val dt = min(0.05f, (now - last) / 1e9f)
            last = now
            val t = finger ?: phone.value
            val k = 1f - exp(-dt / if (now - start < INTRO_NS) 0.45f else 0.08f)
            val p = shown.value
            shown.value = Offset(p.x + (t.x - p.x) * k, p.y + (t.y - p.y) * k)
        }
    }
    Box(
        modifier
            .fillMaxWidth()
            .aspectRatio(1.586f)
            .then(if (reduced) Modifier else Modifier.pointerInput(Unit) { trackFinger { finger = it } })
            .graphicsLayer {
                val p = shown.value
                if (!reduced) {
                    rotationY = p.x * MAX_DEG
                    rotationX = -p.y * MAX_DEG
                }
                cameraDistance = 14f * density
                shadowElevation = 14.dp.toPx()
                ambientShadowColor = Color(0xFF2A2E33)
                spotShadowColor = Color(0xFF2A2E33)
                shape = CardShape
                clip = true
            }
            .drawWithCache {
                val rings = brushedRings()
                onDrawBehind { drawSilver(shown.value, rings) }
            }
            .border(1.dp, Rim, CardShape),
    ) {
        Column(Modifier.fillMaxSize().padding(start = 14.dp, end = 12.dp, top = 6.dp, bottom = 18.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Row(
                    Modifier
                        .weight(1f, fill = false)
                        .heightIn(min = 44.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .clickable(onClickLabel = stringResource(AppR.string.profile_name_edit), role = Role.Button, onClick = onEditName)
                        .padding(horizontal = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        name.ifEmpty { stringResource(AppR.string.profile_name_placeholder) }, Modifier.weight(1f, fill = false),
                        style = Type.Title.copy(shadow = Engraved), color = if (name.isEmpty()) CardMuted else CardInk,
                        maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                    Icon(Glyphs.Pencil, null, Modifier.size(16.dp), tint = CardMuted)
                }
                Icon(Glyphs.Disc, null, Modifier.size(40.dp), tint = CardInk)
            }
            Spacer(Modifier.weight(1f))
            Row(Modifier.padding(start = 6.dp), verticalAlignment = Alignment.Bottom) {
                Column(Modifier.weight(1f)) {
                    Text(stringResource(AppR.string.profile_collection_value), style = Type.Label.copy(shadow = Engraved), color = CardMuted)
                    Text(Price.format(value, currentLanguage()), style = Type.Display.copy(shadow = Engraved), color = CardInk, maxLines = 1)
                }
                Text(
                    pluralStringResource(AppR.plurals.disc_count, discs, discs), Modifier.padding(start = 8.dp, end = 6.dp, bottom = 5.dp),
                    style = Type.Body.copy(shadow = Engraved), color = CardInk,
                )
            }
        }
    }
}

/** Finger position as a Tilt while it touches the card, then null. Watches only: taps and scroll still work. */
private suspend fun PointerInputScope.trackFinger(onTilt: (Tilt?) -> Unit) = awaitEachGesture {
    fun at(p: Offset) = Tilt((p.x / size.width * 2 - 1).coerceIn(-1f, 1f), (p.y / size.height * 2 - 1).coerceIn(-1f, 1f))
    try {
        val down = awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
        onTilt(at(down.position))
        while (true) {
            val c = awaitPointerEvent(PointerEventPass.Initial).changes.firstOrNull { it.id == down.id } ?: break
            if (!c.pressed) break
            onTilt(at(c.position))
        }
    } finally {
        onTilt(null)
    }
}

/** Fine concentric brush lines, drawn once per size. Fixed seed: same metal every time. */
private fun CacheDrawScope.brushedRings(): ImageBitmap {
    val img = ImageBitmap(size.width.roundToInt().coerceAtLeast(1), size.height.roundToInt().coerceAtLeast(1))
    val rnd = Random(7)
    val max = hypot(size.width, size.height) / 2
    val line = Stroke(width = 1f)
    CanvasDrawScope().draw(this, layoutDirection, Canvas(img), size) {
        var r = 1.5f
        while (r < max) {
            val a = rnd.nextFloat()
            val color = if (rnd.nextBoolean()) Color.White.copy(alpha = 0.05f + 0.22f * a) else Color.Black.copy(alpha = 0.02f + 0.07f * a)
            drawCircle(color, r, center, style = line)
            r += 1.4f
        }
        // A few soft dark bands, like the gaps between tracks on a record.
        repeat(5) {
            val br = max * (0.3f + 0.7f * rnd.nextFloat())
            drawCircle(Color.Black.copy(alpha = 0.05f), br, center, style = Stroke(width = 2.5f * density))
        }
    }
    return img
}

/** [p]: shown tilt. Light sits where the card is pushed away. */
internal fun DrawScope.drawSilver(p: Offset, rings: ImageBitmap? = null) {
    val w = size.width
    val h = size.height
    val reach = min(1f, hypot(p.x, p.y))
    val shift = p.x * w * 0.3f + p.y * h * 0.3f
    // Cool silver with wide soft bands that slide with the tilt.
    drawRect(Brush.linearGradient(Base, start = Offset(shift, 0f), end = Offset(w + shift, h), tileMode = TileMode.Mirror))
    if (rings != null) drawImage(rings)
    // Round brushing reflects as two bright lobes through the center; they turn with the tilt.
    val bright = Color.White.copy(alpha = 0.45f + 0.35f * reach)
    val dark = Color.Black.copy(alpha = 0.1f)
    val clear = Color.White.copy(alpha = 0f)
    // The sweep wraps at 0 / 1: keep that in a clear zone, or it shows as a thin seam.
    val lobes = Brush.sweepGradient(
        0f to clear, 0.045f to clear, 0.125f to bright, 0.205f to clear, 0.375f to dark, 0.545f to clear,
        0.625f to bright, 0.705f to clear, 0.875f to dark, 0.96f to clear, 1f to clear,
        center = center,
    )
    rotate(-15f + p.x * 70f + p.y * 45f, center) { drawCircle(lobes, hypot(w, h) / 2 + 1f, center) }
    // Slight rainbow, kept only around the light.
    val light = Offset((0.5f + 0.5f * p.x) * w, (0.5f + 0.5f * p.y) * h)
    drawContext.canvas.saveLayer(size.toRect(), Paint())
    drawRect(
        Brush.linearGradient(Rainbow, start = Offset(shift * 1.5f - w * 0.2f, 0f), end = Offset(shift * 1.5f + w * 0.6f, h), tileMode = TileMode.Mirror),
        alpha = 0.12f + 0.2f * reach,
    )
    drawRect(Brush.radialGradient(listOf(Color.Black, Color.Transparent), light, w * 0.6f), blendMode = BlendMode.DstIn)
    drawContext.canvas.restore()
    // Glare.
    drawRect(
        Brush.radialGradient(listOf(Color.White.copy(alpha = 0.5f), Color.White.copy(alpha = 0.12f), Color.Transparent), light, w * 0.7f),
        alpha = 0.5f + 0.5f * reach,
    )
}
