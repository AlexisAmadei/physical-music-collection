package dev.kiwi.vinyl.ui

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.Stable
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LifecycleResumeEffect
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.min

/**
 * Phone tilt shared by all holo silver (Profile card, Color stickers): one sensor for the app.
 * The sensor runs only while something on screen reads it, the app is resumed and motion is on.
 */
@Stable
class HoloLight {
    internal var readers by mutableIntStateOf(0)
    /** Raw phone tilt, zero at the pose on resume. */
    internal val tilt = mutableStateOf(Tilt.Zero)
    /** Eased tilt, as a light position for [drawSilver]. */
    internal val light = mutableStateOf(Offset.Zero)
}

val LocalHoloLight = staticCompositionLocalOf { HoloLight() }

@Composable
fun ProvideHoloLight(content: @Composable () -> Unit) {
    val holo = remember { HoloLight() }
    val reduced = rememberReducedMotion()
    val active by remember { derivedStateOf { holo.readers > 0 } }
    if (!reduced && active) {
        PhoneTiltEffect(holo.tilt)
        LaunchedEffect(Unit) {
            var last = 0L
            while (true) withFrameNanos { now ->
                val dt = if (last == 0L) 0f else min(0.05f, (now - last) / 1e9f)
                last = now
                val t = holo.tilt.value
                val p = holo.light.value
                val k = 1f - exp(-dt / 0.08f)
                val next = Offset(p.x + (t.x - p.x) * k, p.y + (t.y - p.y) * k)
                // Still phone: no write, so no redraw.
                if (abs(next.x - p.x) + abs(next.y - p.y) > 1e-4f) holo.light.value = next
            }
        }
    }
    CompositionLocalProvider(LocalHoloLight provides holo, content = content)
}

/** Raw phone tilt (Tilt.Zero with reduced motion). Keeps the sensor on while in composition. */
@Composable
fun rememberHoloTilt(): State<Tilt> = LocalHoloLight.current.also { ReadHolo(it) }.tilt

/** Eased light position for [drawSilver]. Fixed at [StillLight] with reduced motion. */
@Composable
fun rememberHoloLight(): State<Offset> {
    if (rememberReducedMotion()) return remember { mutableStateOf(StillLight) }
    return LocalHoloLight.current.also { ReadHolo(it) }.light
}

@Composable
private fun ReadHolo(holo: HoloLight) = DisposableEffect(holo) {
    holo.readers++
    onDispose { holo.readers-- }
}

/** Phone pose into [target], zero at the pose on resume. Sensor runs only while resumed. */
@Composable
private fun PhoneTiltEffect(target: MutableState<Tilt>) {
    val ctx = LocalContext.current
    LifecycleResumeEffect(Unit) {
        val sm = ctx.getSystemService(SensorManager::class.java)
        // Game rotation vector: gyro + accel, no compass jumps. Older phones: the plain one.
        val sensor = sm?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR) ?: sm?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val tracker = TiltTracker()
        val q = FloatArray(4)
        var last = 0L
        val listener = object : SensorEventListener {
            override fun onSensorChanged(e: SensorEvent) {
                SensorManager.getQuaternionFromVector(q, e.values)
                val dt = if (last == 0L) 0f else min(0.1f, (e.timestamp - last) / 1e9f)
                last = e.timestamp
                target.value = tracker.update(q, dt)
            }
            override fun onAccuracyChanged(s: Sensor?, accuracy: Int) {}
        }
        if (sensor != null) sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME)
        onPauseOrDispose {
            sm?.unregisterListener(listener)
            target.value = Tilt.Zero
        }
    }
}
