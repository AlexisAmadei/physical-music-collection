package dev.kiwi.vinyl.ui

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.cos
import kotlin.math.sin

class TiltTrackerTest {
    /** Unit quaternion (w, x, y, z) for [deg] degrees about the unit axis (ax, ay, az). */
    private fun q(deg: Double, ax: Float, ay: Float, az: Float): FloatArray {
        val h = Math.toRadians(deg) / 2
        val s = sin(h).toFloat()
        return floatArrayOf(cos(h).toFloat(), ax * s, ay * s, az * s)
    }

    /** [b] applied after [a]: b · a. */
    private fun then(a: FloatArray, b: FloatArray) = floatArrayOf(
        b[0] * a[0] - b[1] * a[1] - b[2] * a[2] - b[3] * a[3],
        b[0] * a[1] + b[1] * a[0] + b[2] * a[3] - b[3] * a[2],
        b[0] * a[2] - b[1] * a[3] + b[2] * a[0] + b[3] * a[1],
        b[0] * a[3] + b[1] * a[2] - b[2] * a[1] + b[3] * a[0],
    )

    private fun assertFlat(t: Tilt) {
        assertEquals(0f, t.x, 1e-5f)
        assertEquals(0f, t.y, 1e-5f)
    }

    private val hold = q(55.0, -1f, 0f, 0f) // phone held up at 55°, any pose works as zero
    private val dt = 0.02f

    @Test fun firstSampleIsFlat() {
        assertFlat(TiltTracker().update(hold, dt))
    }

    @Test fun halfRangeTurnGivesHalfTilt() {
        val t = TiltTracker()
        t.update(hold, dt)
        val r = t.update(then(q(7.5, 0f, 1f, 0f), hold), dt) // twist about device Y
        assertEquals(0.5f, r.x, 0.02f)
        assertEquals(0f, r.y, 0.02f)
        val t2 = TiltTracker()
        t2.update(hold, dt)
        val r2 = t2.update(then(q(-7.5, 1f, 0f, 0f), hold), dt) // tip about device X
        assertEquals(0f, r2.x, 0.02f)
        assertEquals(-0.5f, r2.y, 0.02f)
    }

    @Test fun clampsPastRange() {
        val t = TiltTracker()
        t.update(hold, dt)
        assertEquals(1f, t.update(then(q(40.0, 0f, 1f, 0f), hold), dt).x, 0f)
    }

    @Test fun heldTiltFadesBackToFlat() {
        val t = TiltTracker()
        t.update(hold, dt)
        val tipped = then(q(10.0, 0f, 1f, 0f), hold)
        var r = Tilt.Zero
        repeat((20f / dt).toInt()) { r = t.update(tipped, dt) }
        assertEquals(0f, r.x, 0.01f)
    }

    @Test fun signFlippedQuaternionIsSamePose() {
        val t = TiltTracker()
        t.update(hold, dt)
        val tipped = then(q(7.5, 0f, 1f, 0f), hold)
        val r = t.update(FloatArray(4) { -tipped[it] }, dt)
        assertEquals(0.5f, r.x, 0.02f)
    }

    @Test fun resetTakesNewZero() {
        val t = TiltTracker()
        t.update(hold, dt)
        t.reset()
        assertFlat(t.update(then(q(10.0, 0f, 1f, 0f), hold), dt))
    }
}
