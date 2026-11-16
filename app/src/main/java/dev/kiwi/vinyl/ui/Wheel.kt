package dev.kiwi.vinyl.ui

import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import dev.kiwi.vinyl.data.Disc
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

private const val N = 10                       // slots on the wheel
private const val STEP = 360f / N              // 36°
private const val CARD = 200f                  // dp
private val RADIUS = ((CARD + 20) / (2 * sin(PI / N))).toFloat() // ≈ 356 dp
private const val PERSPECTIVE = 1000f          // dp
private const val K = 118f                     // spring stiffness (critically damped)
private const val DRIFT = 10f                  // °/s, upwards
private const val MAX_FLING = 1400f            // °/s
private const val TOUCH_HOLD = 2_500L          // ms of pause after touch
private const val FOCUS_HOLD = 2_800L          // ms of pause after tap
private const val SLIDE_OUT_MS = 500
private const val SLIDE_BACK_MS = 300

private fun nearest(a: Float) = (a / STEP).roundToInt() * STEP

/**
 * Wheel position as an endless tape: card k sits at angle `k·STEP + angle`, shows disc k mod n.
 * Only the 10 cards around the front are drawn, so collections of any size scroll through in order;
 * a card changes disc only while it is hidden directly behind the front cards.
 */
private class WheelState(private val frozen: () -> Boolean) { // frozen: a sleeve is open, no drift
    var angle by mutableFloatStateOf(0f)
    var dragging by mutableStateOf(false)
    var touching = false
    private var vel = 0f
    private var target: Float? = null
    private var holdUntil = 0L

    val front by derivedStateOf { (-angle / STEP).roundToInt() }

    fun hold(ms: Long) { holdUntil = System.nanoTime() + ms * 1_000_000 }
    fun theta(k: Int) = k * STEP + angle

    fun focus(k: Int) { target = -k * STEP; hold(FOCUS_HOLD) }
    fun stepBy(cards: Int) { target = (target ?: nearest(angle)) - cards * STEP; hold(FOCUS_HOLD) }

    fun startDrag() { target = null; vel = 0f; dragging = true }
    fun endDrag(degPerSec: Float) {
        if (!dragging) return
        target = nearest(angle + degPerSec.coerceIn(-MAX_FLING, MAX_FLING) * 0.25f)
        hold(TOUCH_HOLD); dragging = false
    }

    suspend fun run(drift: Boolean) {
        var last = 0L
        while (true) withFrameNanos { now ->
            val dt = if (last == 0L) 1 / 60f else min((now - last) / 1e9f, 0.05f)
            last = now
            if (!dragging) tick(dt, drift && !frozen() && !touching && System.nanoTime() >= holdUntil)
        }
    }

    private fun tick(dt: Float, drifting: Boolean) {
        var a = angle
        val t = target
        if (t != null) {
            val damp = 2 * sqrt(K)
            var rem = dt
            while (rem > 0) {
                val h = min(rem, 1 / 240f)
                vel += (K * (t - a) - damp * vel) * h
                a += vel * h
                rem -= h
            }
            if (abs(t - a) < 0.01f && abs(vel) < 0.05f) { a = t; target = null; vel = 0f }
        } else if (drifting) {
            a -= DRIFT * dt
        } else if (abs(a - nearest(a)) > 0.01f) {
            target = nearest(a)
        }
        if (a != angle) angle = a
    }
}

private val SlideEase = CubicBezierEasing(0.2f, 0.8f, 0.2f, 1f)

/**
 * Open sleeve on the Home wheel. FRONT → FLIPPING → DISC_OUT, then the reverse.
 * The vinyl comes out once the sleeve first faces backwards (the flip's overshoot settles meanwhile),
 * and is tucked back in before the sleeve turns. Every step can be interrupted: a new open or close
 * picks up from wherever the sleeve is.
 */
private class FlipState(private val reduced: Boolean, private val scope: CoroutineScope) {
    val rot = Animatable(0f)
    val slide = Animatable(0f) // 0 = hidden behind the sleeve, 1 = 78 dp out
    var k by mutableStateOf<Int?>(null) // wheel index of the open disc
    var discVisible by mutableStateOf(false)
    var spinning by mutableStateOf(false)
    var closing by mutableStateOf(false)
    private var job: Job? = null

    /** Open or opening: the wheel holds still. A closing sleeve already lets it go. */
    val holding get() = k != null && !closing

    fun open(index: Int) {
        job?.cancel()
        job = scope.launch {
            if (k != null && k != index) reset() // another sleeve still settling: shut it at once
            k = index; closing = false
            if (reduced) { rot.snapTo(180f); discVisible = true; slide.snapTo(1f); return@launch }
            coroutineScope {
                if (rot.value < 180f) launch { rot.animateTo(180f, tween(FLIP_OPEN_MS, easing = FlipEase)) }
                snapshotFlow { rot.value }.first { it >= 180f }
                discVisible = true
                slide.animateTo(1f, tween(SLIDE_OUT_MS, easing = SlideEase))
                spinning = true
            }
        }
    }

    fun close() {
        if (!holding) return
        job?.cancel()
        closing = true; spinning = false
        job = scope.launch {
            if (!reduced) {
                if (discVisible) slide.animateTo(0f, tween(SLIDE_BACK_MS))
                discVisible = false
                rot.animateTo(0f, tween(FLIP_CLOSE_MS, easing = FlipEase))
            }
            reset()
        }
    }

    private suspend fun reset() {
        rot.snapTo(0f); slide.snapTo(0f)
        discVisible = false; spinning = false; closing = false; k = null
    }
}

/** Home carousel: covers on a vertical 3D wheel, front card centred on the screen. */
@Composable
fun CoverWheel(discs: List<Disc>, onOpen: (Disc) -> Unit, modifier: Modifier = Modifier) {
    val ctx = LocalContext.current
    val reduced = remember { Settings.Global.getFloat(ctx.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    val scope = rememberCoroutineScope()
    val flip = remember { FlipState(reduced, scope) }
    val wheel = remember { WheelState(frozen = { flip.holding }) }
    BackHandler(flip.holding) { flip.close() }
    LaunchedEffect(reduced) { wheel.run(drift = !reduced) }
    val n = discs.size
    val disc = { k: Int -> discs[Math.floorMod(k, n)] }
    // Closing never blocks the wheel: it turns toward the tapped card while the sleeve shuts.
    val tap = { k: Int ->
        when {
            flip.holding -> { flip.close(); if (k != wheel.front) wheel.focus(k) }
            k == wheel.front -> { wheel.focus(k); flip.open(k) }
            else -> wheel.focus(k)
        }
    }

    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth
        val h = maxHeight
        Box(
            Modifier
                .width(w - 72.dp) // stop before the nav pill
                .fillMaxHeight()
                .clipToBounds()
                .fadeEdges()
                .semantics {
                    contentDescription = "Ma collection"
                    customActions = listOf(
                        CustomAccessibilityAction("Disque suivant") { flip.close(); wheel.stepBy(1); true },
                        CustomAccessibilityAction("Disque précédent") { flip.close(); wheel.stepBy(-1); true },
                    )
                }
                .pointerInput(Unit) { // pause while any finger is down, without consuming
                    awaitEachGesture {
                        awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
                        wheel.touching = true
                        do { val e = awaitPointerEvent(PointerEventPass.Initial) } while (e.changes.any { it.pressed })
                        wheel.touching = false
                        wheel.hold(TOUCH_HOLD)
                    }
                }
                .pointerInput(Unit) {
                    val degPerPx = 180f / (PI.toFloat() * RADIUS.dp.toPx())
                    val tracker = VelocityTracker()
                    detectVerticalDragGestures(
                        onDragStart = { tracker.resetTracking(); flip.close(); wheel.startDrag() },
                        onDragEnd = { wheel.endDrag(tracker.calculateVelocity().y * degPerPx) },
                        onDragCancel = { wheel.endDrag(0f) },
                    ) { change, dy ->
                        if (!wheel.dragging) return@detectVerticalDragGestures
                        change.consume()
                        tracker.addPosition(change.uptimeMillis, change.position)
                        wheel.angle += dy * degPerPx
                    }
                },
        ) {
            val front = wheel.front
            for (j in -N / 2 until N / 2) {
                val k = front + j
                key(Math.floorMod(k, N)) {
                    val d = disc(k)
                    val theta = { wheel.theta(k) }
                    val place = Modifier.offset(w / 2 - (CARD / 2).dp, h / 2 - (CARD / 2).dp)
                    // The open sleeve stays on its card, so it rides along when the wheel turns.
                    if (flip.k == k) Sleeve(d, flip, theta, onTap = { tap(k) }, onEdit = { onOpen(d) }, place)
                    else WheelCard(d, theta, onClick = { tap(k) }, place)
                }
            }
        }
        // Polite announcement of the front disc (TalkBack).
        Box(Modifier.size(1.dp).clearAndSetSemantics {
            liveRegion = LiveRegionMode.Polite
            contentDescription = disc(wheel.front).a11yLabel()
        })
        PositionIndicator(
            fraction = { if (n < 2) 0f else Math.floorMod(wheel.front, n) / (n - 1f) },
            modifier = Modifier.offset(w - 79.5.dp, h / 2 - 51.5.dp),
        )
    }
}

@Composable
private fun WheelCard(d: Disc, theta: () -> Float, onClick: () -> Unit, modifier: Modifier) {
    Box(
        modifier
            .size(CARD.dp)
            .onWheel(theta)
            .shadow(5.dp, ambientColor = Color.Black.copy(alpha = 0.25f), spotColor = Color.Black.copy(alpha = 0.25f))
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = d.a11yLabel() },
    ) {
        Cover(d.coverUrl, Modifier.matchParentSize())
        ColorStickerOf(d)
        // White veil, stronger towards the back of the wheel.
        Box(Modifier.matchParentSize().drawBehind {
            val facing = cos(theta() * PI.toFloat() / 180)
            val fade = 0.55f * Math.pow(((1 - facing) / 2).toDouble(), 1.25).toFloat()
            drawRect(Color.White, alpha = fade)
        })
    }
}

/** Front card turned into an open sleeve: [FlipFaces] with the vinyl sliding out to its left. */
@Composable
private fun Sleeve(d: Disc, flip: FlipState, theta: () -> Float, onTap: () -> Unit, onEdit: () -> Unit, modifier: Modifier) {
    Box(modifier.size(CARD.dp).onWheel(theta), contentAlignment = Alignment.Center) {
        if (flip.discVisible) Vinyl(d, flip.spinning, Modifier.offset { IntOffset((-78.dp.toPx() * flip.slide.value).roundToInt(), 0) })
        FlipFaces(d, flip.rot.value, onTap, onEdit, Modifier.size(CARD.dp), large = true, elevation = 5.dp)
    }
}

/** Places a card on the wheel at [theta] degrees. All per-frame work happens in placement, not composition. */
private fun Modifier.onWheel(theta: () -> Float) = layout { m, c ->
    val p = m.measure(c)
    layout(p.width, p.height) {
        val t = theta()
        val rad = t * PI.toFloat() / 180
        val r = RADIUS.dp.toPx()
        p.placeWithLayer(0, 0, zIndex = cos(rad)) {
            translationY = r * sin(rad)
            val s = PERSPECTIVE / (PERSPECTIVE + RADIUS * (1 - cos(rad)))
            scaleX = s; scaleY = s
            rotationX = -t
            cameraDistance = PERSPECTIVE.dp.toPx() / 72f // RenderNode units: 1 = 72 px
        }
    }
}

/** Vertical fade: transparent 56 → opaque 120 dp from the top, mirrored 65 → 117 dp from the bottom. */
private fun Modifier.fadeEdges() = graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .drawWithContent {
        drawContent()
        val hh = size.height
        fun top(dp: Float) = (dp * density / hh).coerceIn(0f, 1f)
        fun bottom(dp: Float) = (1 - dp * density / hh).coerceIn(0f, 1f)
        drawRect(
            Brush.verticalGradient(
                0f to Color.Transparent, top(56f) to Color.Transparent, top(120f) to Color.Black,
                bottom(117f) to Color.Black, bottom(65f) to Color.Transparent, 1f to Color.Transparent,
            ),
            blendMode = BlendMode.DstIn,
        )
    }

@Composable
private fun PositionIndicator(fraction: () -> Float, modifier: Modifier) {
    Box(modifier.size(3.dp, 103.dp).background(Palette.Line, RoundedCornerShape(2.dp))) {
        Box(
            Modifier
                .offset { IntOffset(0, (fraction() * 59.dp.toPx()).roundToInt()) }
                .size(3.dp, 44.dp)
                .background(Palette.Thumb, RoundedCornerShape(2.dp)),
        )
    }
}
