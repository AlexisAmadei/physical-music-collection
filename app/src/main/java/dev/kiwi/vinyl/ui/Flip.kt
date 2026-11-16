package dev.kiwi.vinyl.ui

import android.provider.Settings
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.Format
import dev.kiwi.vinyl.data.Price
import dev.kiwi.vinyl.data.shownVinylColor
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.random.Random

/** cubic-bezier(.3, 1.45, .55, 1): light overshoot (~5 %) at the end of the flip. */
val FlipEase = CubicBezierEasing(0.3f, 1.45f, 0.55f, 1f)
const val FLIP_OPEN_MS = 750
const val FLIP_CLOSE_MS = 800

@Composable
fun rememberReducedMotion(): Boolean {
    val ctx = LocalContext.current
    return remember { Settings.Global.getFloat(ctx.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
}

/**
 * Cover that flips on its Y axis (0.75 s, light spring) to show the record's details, blurred
 * cover behind a white glass veil. Tap toggles; the pencil on the back calls [onEdit].
 */
@Composable
fun FlipCover(d: Disc, flipped: Boolean, onFlip: () -> Unit, onEdit: () -> Unit, modifier: Modifier = Modifier) {
    val reduced = rememberReducedMotion()
    val rot by animateFloatAsState(
        if (flipped) 180f else 0f,
        if (reduced) tween(0) else tween(if (flipped) FLIP_OPEN_MS else FLIP_CLOSE_MS, easing = FlipEase),
        label = "flip",
    )
    FlipFaces(d, rot, onFlip, onEdit, modifier)
}

/** Both faces for an explicit [rotation] (degrees, 0 = front, 180 = back). Back shows past 90°. */
@Composable
fun FlipFaces(
    d: Disc, rotation: Float, onTap: () -> Unit, onEdit: () -> Unit, modifier: Modifier = Modifier,
    large: Boolean = false, elevation: Dp = 4.dp,
) {
    val m = ((rotation % 360f) + 360f) % 360f
    val back = m in 90f..270f
    Box(
        modifier
            .graphicsLayer {
                rotationY = rotation
                cameraDistance = 1100.dp.toPx() / 72f // RenderNode units: 1 = 72 px
            }
            .shadow(elevation, ambientColor = Color.Black.copy(alpha = 0.25f), spotColor = Color.Black.copy(alpha = 0.25f)),
    ) {
        if (!back) {
            Cover(
                d.coverUrl,
                Modifier.fillMaxSize()
                    .clickable(onClickLabel = "Retourner", role = Role.Button, onClick = onTap)
                    .semantics { contentDescription = d.a11yLabel() },
            )
            ColorStickerOf(d)
        } else {
            Box(Modifier.fillMaxSize().graphicsLayer { rotationY = 180f }) { BackFace(d, onTap, onEdit, large) }
        }
    }
}

@Composable
private fun BackFace(d: Disc, onTap: () -> Unit, onEdit: () -> Unit, large: Boolean) {
    val pad = if (large) 18.dp else 14.dp
    val star = if (large) 13.dp else 12.dp
    // Seen price in the Wishlist, Paid price in the Collection; the other one stays hidden.
    val price = if (d.wishlist) d.seenPrice?.let { "Vu à ${Price.format(it)}" } else d.paidPrice?.let { "Payé ${Price.format(it)}" }
    Box(Modifier.fillMaxSize().clipToBounds().clickable(onClickLabel = "Retourner", role = Role.Button, onClick = onTap)) {
        Cover(
            d.coverUrl,
            Modifier.fillMaxSize().graphicsLayer { scaleX = 1.24f; scaleY = 1.24f }.saturate(1.6f).blur(14.dp),
        )
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.72f), Color.White.copy(alpha = 0.55f)))))
        Column(Modifier.fillMaxSize().padding(pad), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            if (d.artist.isNotBlank()) {
                Text(
                    d.artist.uppercase(), maxLines = 1, overflow = TextOverflow.Ellipsis,
                    style = Type.Label.copy(fontSize = if (large) 11.sp else 10.sp, fontWeight = FontWeight.Medium, letterSpacing = 0.6.sp),
                    color = Color(0xFF5A3A3A),
                )
            }
            Text(
                // The extra price line would push a 3-line title into the barcode on small cards.
                d.title.ifBlank { "Sans titre" }, maxLines = if (price != null && !large) 2 else 3, overflow = TextOverflow.Ellipsis,
                style = Type.Title.copy(fontSize = if (large) 17.sp else 15.sp, lineHeight = if (large) 21.sp else 19.sp),
                color = Palette.Ink,
            )
            Text(
                listOfNotNull(d.year?.toString(), if (d.format == Format.CD) "CD" else "Vinyle").joinToString(" · "),
                style = Type.Label, color = Palette.Ink,
            )
            Text("Ajouté le ${addedOn(d.addedAt)}", style = Type.Label.copy(fontSize = 11.sp), color = Palette.Ink.copy(alpha = 0.7f))
            if (price != null) Text(price, style = Type.Label, color = Palette.Ink)
            if (!d.wishlist) StarRating(d.rating, size = star)
        }
        Barcode(d.id * 31 + d.title.hashCode(), Modifier.align(Alignment.BottomStart).padding(start = pad, bottom = pad))
        PencilButton(onEdit, Modifier.align(Alignment.BottomEnd).padding(end = 8.dp, bottom = 8.dp))
    }
}

private val DateFmt = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.FRENCH)
private fun addedOn(ms: Long): String = DateFmt.format(Instant.ofEpochMilli(ms).atZone(ZoneId.systemDefault()))

/** 44 dp glass-look round button (the haze backdrop does not follow a rotated layer, so a plain wash). */
@Composable
private fun PencilButton(onClick: () -> Unit, modifier: Modifier) {
    Box(
        modifier
            .size(44.dp)
            .shadow(6.dp, CircleShape, ambientColor = Color.Black.copy(alpha = 0.2f), spotColor = Color.Black.copy(alpha = 0.2f))
            .clip(CircleShape)
            .background(Brush.linearGradient(listOf(Color.White.copy(alpha = 0.75f), Color(0xFFF0F0F0).copy(alpha = 0.5f))))
            .border(1.dp, Color.White.copy(alpha = 0.9f), CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = "Modifier le disque" },
        contentAlignment = Alignment.Center,
    ) { Icon(Glyphs.Pencil, null, Modifier.size(22.dp), tint = Palette.Ink) }
}

/** Decorative barcode, stable per record. */
@Composable
private fun Barcode(seed: Long, modifier: Modifier) {
    Canvas(modifier.size(56.dp, 18.dp)) {
        val rnd = Random(seed)
        var x = 0f
        while (x < size.width) {
            val w = (0.8f + rnd.nextInt(3) * 0.8f).dp.toPx()
            drawRect(Palette.Ink, Offset(x, 0f), Size(minOf(w, size.width - x), size.height))
            x += w + (0.8f + rnd.nextInt(2) * 0.8f).dp.toPx()
        }
    }
}

private fun Modifier.saturate(amount: Float) = drawWithContent {
    val paint = Paint().apply { colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(amount) }) }
    drawIntoCanvas { c ->
        c.saveLayer(Rect(Offset.Zero, size), paint)
        drawContent()
        c.restore()
    }
}

/**
 * The record that slides out of the sleeve: 188 dp disc (black, or its Vinyl color), grooves, round cover as label,
 * 8 dp hole. Spins while [spinning] (1 turn / 1.8 s); the highlight stays fixed.
 */
@Composable
fun Vinyl(d: Disc, spinning: Boolean, modifier: Modifier = Modifier) {
    var angle by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(spinning) {
        if (!spinning) return@LaunchedEffect
        var last = 0L
        while (true) withFrameNanos { now ->
            if (last != 0L) angle = (angle + (now - last) / 1e9f * 200f) % 360f
            last = now
        }
    }
    Box(modifier.size(188.dp)) {
        Box(Modifier.fillMaxSize().graphicsLayer { rotationZ = angle }, contentAlignment = Alignment.Center) {
            // Vinyl color only shows for vinyl; a CD keeps its hidden value.
            val wax = d.shownVinylColor
            val groove = if (wax?.light == true) Color.Black.copy(alpha = 0.10f) else Color.White.copy(alpha = 0.07f)
            Canvas(Modifier.fillMaxSize()) {
                drawCircle(wax?.let { Color(it.argb) } ?: Color(0xFF121212))
                val outer = size.minDimension / 2
                var r = outer * 0.36f
                while (r < outer - 2.dp.toPx()) {
                    drawCircle(groove, r, style = Stroke(0.8.dp.toPx()))
                    r += 3.dp.toPx()
                }
            }
            Cover(d.coverUrl, Modifier.size(64.dp).clip(CircleShape))
            Canvas(Modifier.size(8.dp)) { drawCircle(Color.White) }
        }
        Canvas(Modifier.fillMaxSize()) {
            val wedge = Color.White.copy(alpha = 0.13f)
            drawCircle(
                Brush.sweepGradient(
                    0f to Color.Transparent, 0.06f to wedge, 0.12f to Color.Transparent,
                    0.5f to Color.Transparent, 0.56f to wedge, 0.62f to Color.Transparent, 1f to Color.Transparent,
                ),
            )
        }
    }
}
