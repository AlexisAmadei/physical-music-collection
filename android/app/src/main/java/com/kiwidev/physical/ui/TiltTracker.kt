package com.kiwidev.physical.ui

import kotlin.math.exp

/** Card tilt, each axis in -1..1. x > 0: right edge pushed away. y > 0: bottom edge pushed away. */
data class Tilt(val x: Float, val y: Float) {
    companion object { val Zero = Tilt(0f, 0f) }
}

/**
 * Phone pose → [Tilt]. Zero is the pose of the first sample, so any hold angle works (sofa, bed).
 * The zero then drifts after the phone ([recenterSec] time constant): a held tilt fades back to flat.
 *
 * Poses are unit quaternions (w, x, y, z), device → world, as from `SensorManager.getQuaternionFromVector`.
 */
class TiltTracker(
    private val rangeRad: Float = Math.toRadians(15.0).toFloat(),
    private val recenterSec: Float = 3f,
) {
    private var base: FloatArray? = null

    fun reset() { base = null }

    fun update(q: FloatArray, dtSec: Float): Tilt {
        val b = base ?: q.copyOf().also { base = it }
        // Same rotation, other sign: keep q on b's side so the blend below takes the short way.
        val cur = if (dot(b, q) < 0f) FloatArray(4) { -q[it] } else q
        val rel = mul(conj(b), cur) // current device frame → zero frame
        val s = if (rel[0] < 0f) -2f else 2f // small angle: 2 · vector part ≈ rotation in radians
        val tilt = Tilt(
            x = (s * rel[2] / rangeRad).coerceIn(-1f, 1f), // about device Y: +X goes to -Z, right edge away
            y = (s * rel[1] / rangeRad).coerceIn(-1f, 1f), // about device X: +Y comes to +Z, bottom edge away
        )
        val k = 1f - exp(-dtSec / recenterSec)
        for (i in 0..3) b[i] += (cur[i] - b[i]) * k
        normalize(b)
        return tilt
    }

    private fun dot(a: FloatArray, b: FloatArray) = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
    private fun conj(a: FloatArray) = floatArrayOf(a[0], -a[1], -a[2], -a[3])
    private fun mul(a: FloatArray, b: FloatArray) = floatArrayOf(
        a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3],
        a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
        a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1],
        a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0],
    )
    private fun normalize(a: FloatArray) {
        val n = kotlin.math.sqrt(dot(a, a))
        if (n > 0f) for (i in 0..3) a[i] /= n
    }
}
