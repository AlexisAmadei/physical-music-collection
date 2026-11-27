package com.kiwidev.physical.ui

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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
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
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kiwidev.physical.R as AppR
import com.kiwidev.physical.data.CollectionStats
import com.kiwidev.physical.data.Price
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
/** Portrait, like a trading card. */
private const val RATIO = 0.63f
/** The intro starts lit from the top right, then settles. */
private val IntroStart = Offset(0.62f, -0.55f)
/** Reduced motion: no tilt, light fixed here. */
internal val StillLight = Offset(0.35f, -0.3f)

/** Along the brush lines, on screen: from bottom left to top right. */
private val Grain = Offset(0.7071f, -0.7071f)
/** Shown when no Collection Disc has a year. */
private const val NO_YEAR = "–"

/**
 * The Profile card: a portrait silver card, brushed in diagonal lines, with the Profile name and the
 * [CollectionStats]. Tilts with the phone, and with the finger while it touches. One soft streak of light
 * crosses the lines and slides along them with the tilt; a slight rainbow shows only where the light hits.
 */
@Composable
fun ProfileCard(name: String, stats: CollectionStats, onEditName: () -> Unit, modifier: Modifier = Modifier) {
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
    val language = currentLanguage()
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Box(
            Modifier
                .fillMaxWidth(0.7f)
                .widthIn(max = 320.dp)
                .aspectRatio(RATIO)
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
                    val lines = brushedLines()
                    onDrawBehind { drawSilver(shown.value, lines) }
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
                    Icon(Glyphs.Disc, null, Modifier.padding(start = 8.dp).size(40.dp), tint = CardInk)
                }
                Spacer(Modifier.weight(1f))
                Column(Modifier.padding(horizontal = 6.dp)) {
                    Text(stringResource(AppR.string.profile_collection_value), style = Type.Label.copy(shadow = Engraved), color = CardMuted)
                    BasicText(
                        Price.format(stats.value, language), style = Type.Display.copy(color = CardInk, shadow = Engraved), maxLines = 1,
                        autoSize = TextAutoSize.StepBased(minFontSize = 18.sp, maxFontSize = Type.Display.fontSize),
                    )
                    if (stats.unpriced > 0) {
                        Text(
                            stringResource(AppR.string.profile_without_price, stats.unpriced),
                            style = Type.Label.copy(shadow = Engraved), color = CardMuted,
                        )
                    }
                    Spacer(Modifier.height(20.dp))
                    Row {
                        Stat(stringResource(AppR.string.profile_vinyls), stats.vinyls.toString(), Modifier.weight(1f))
                        Stat(stringResource(AppR.string.profile_cds), stats.cds.toString(), Modifier.weight(1f))
                    }
                    Spacer(Modifier.height(14.dp))
                    Row {
                        Stat(stringResource(AppR.string.profile_colored), stats.colored.toString(), Modifier.weight(1f))
                        Stat(stringResource(AppR.string.profile_oldest), stats.oldestYear?.toString() ?: NO_YEAR, Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

/** A small muted label over its number. Read as one: "Vinyls, 12". */
@Composable
private fun Stat(label: String, value: String, modifier: Modifier = Modifier) {
    Column(modifier.clearAndSetSemantics { contentDescription = "$label, $value" }) {
        Text(label, style = Type.Label.copy(shadow = Engraved), color = CardMuted, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Text(value, style = Type.Title.copy(shadow = Engraved), color = CardInk, maxLines = 1)
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

/** Fine straight brush lines at 45° (along [Grain]), drawn once per size. Fixed seed: same metal every time. */
private fun CacheDrawScope.brushedLines(): ImageBitmap {
    val img = ImageBitmap(size.width.roundToInt().coerceAtLeast(1), size.height.roundToInt().coerceAtLeast(1))
    val rnd = Random(7)
    // Half the diagonal: rotated lines this long still cover the corners.
    val half = hypot(size.width, size.height) / 2
    CanvasDrawScope().draw(this, layoutDirection, Canvas(img), size) {
        // Horizontal lines turned 45° counterclockwise: from bottom left to top right.
        rotate(-45f, center) {
            fun line(y: Float, color: Color, width: Float) =
                drawLine(color, Offset(center.x - half, y), Offset(center.x + half, y), strokeWidth = width)
            var y = center.y - half
            while (y < center.y + half) {
                val a = rnd.nextFloat()
                line(y, if (rnd.nextBoolean()) Color.White.copy(alpha = 0.05f + 0.22f * a) else Color.Black.copy(alpha = 0.02f + 0.07f * a), 1f)
                y += 1.4f
            }
            // A few soft darker bands, where the brush pressed harder.
            repeat(5) { line(center.y + half * (1.8f * rnd.nextFloat() - 0.9f), Color.Black.copy(alpha = 0.05f), 2.5f * density) }
        }
    }
    return img
}

/** [p]: shown tilt. Light sits where the card is pushed away. */
internal fun DrawScope.drawSilver(p: Offset, lines: ImageBitmap? = null) {
    val w = size.width
    val h = size.height
    val diag = hypot(w, h)
    val reach = min(1f, hypot(p.x, p.y))
    val shift = p.x * w * 0.3f + p.y * h * 0.3f
    // Cool silver with wide soft bands that slide with the tilt.
    drawRect(Brush.linearGradient(Base, start = Offset(shift, 0f), end = Offset(w + shift, h), tileMode = TileMode.Mirror))
    if (lines != null) drawImage(lines)
    // Straight brushing reflects as one streak across the lines; the tilt slides it along them.
    val along = (p.x * Grain.x + p.y * Grain.y) * diag * 0.35f
    val mid = center + Grain * along
    val reachOut = Grain * (diag * 0.4f)
    val dark = Color.Black.copy(alpha = 0.08f)
    val clear = Color.White.copy(alpha = 0f)
    drawRect(
        Brush.linearGradient(
            0f to clear, 0.18f to dark, 0.5f to Color.White.copy(alpha = 0.45f + 0.35f * reach), 0.82f to dark, 1f to clear,
            start = mid - reachOut, end = mid + reachOut,
        ),
    )
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
