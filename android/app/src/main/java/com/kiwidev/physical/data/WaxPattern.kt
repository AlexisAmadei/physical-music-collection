package com.kiwidev.physical.data

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * What a Finish looks like, as plain data: no drawing here, so it is the same on both platforms and testable.
 * Mirrors iOS `WaxPattern.swift` (same generator, same steps, same numbers). The look was settled with the browser
 * prototype on branch prototype/vinyl-finishes: Marble is warped noise, Splatter is bursts of elongated droplets.
 */

/** SplitMix64, the same generator as iOS `SeededRandom`: a fixed seed always draws the same thing. */
class WaxRandom(seed: Long) {
    private var state = seed

    fun next(): Long {
        state += GAMMA
        var z = state
        z = (z xor (z ushr 30)) * MIX1
        z = (z xor (z ushr 27)) * MIX2
        return z xor (z ushr 31)
    }

    /** In 0 until 1. */
    fun unit(): Double = (next() ushr 11).toDouble() / (1L shl 53).toDouble()

    private companion object {
        const val GAMMA = -0x61c8864680b583ebL // 0x9E3779B97F4A7C15
        const val MIX1 = -0x40a7b892e31b1a47L // 0xBF58476D1CE4E5B9
        const val MIX2 = -0x6b2fb644ecceee15L // 0x94D049BB133111EB
    }
}

/** The seed of a Disc's pattern. From the creation time: stable across launches and edits, different for each Disc. */
val Disc.waxSeed: Long get() = WaxRandom(addedAt).next()

/** An ellipse on the unit disc (radius 1, origin at the centre, y down), turned by [rot] radians. */
data class Droplet(val x: Double, val y: Double, val rx: Double, val ry: Double, val rot: Double, val alpha: Double, val tone: Int = 0)

/**
 * A flake that flashes when the phone tilts. It has its own flashing angles: [a] and [b], in radians per unit of tilt,
 * and [phase]. [r] is its size on the unit disc. See [WaxPattern.glintLevel].
 */
data class Glint(val x: Double, val y: Double, val r: Double, val a: Double, val b: Double, val phase: Double)

/** Galaxy stars: [dots] are fine white points of varied size, [glows] a few bigger stars drawn with a halo. */
class Stars(val dots: List<Droplet>, val glows: List<Droplet>)

object WaxPattern {
    private const val TAU = 2 * PI

    /** Marble bitmap side, in pixels. One bitmap per Disc, drawn scaled. */
    const val MARBLE_SIZE = 256

    private fun inDisc(rand: WaxRandom, radius: Double): Pair<Double, Double> {
        val a = rand.unit() * TAU
        val d = sqrt(rand.unit()) * radius
        return cos(a) * d to sin(a) * d
    }

    /** Splatter: a few impact points, each a core blob throwing elongated droplets outward. */
    fun splatter(seed: Long): List<Droplet> {
        val rand = WaxRandom(seed)
        val out = ArrayList<Droplet>()
        val impacts = 4 + floor(rand.unit() * 3).toInt()
        repeat(impacts) {
            val (cx, cy) = inDisc(rand, 0.85)
            val core = 5 + floor(rand.unit() * 4).toInt()
            repeat(core) {
                val a = rand.unit() * TAU
                val d = rand.unit() * 0.05
                val r = 0.025 + rand.unit() * 0.05
                out += Droplet(cx + cos(a) * d, cy + sin(a) * d, r, r, 0.0, 0.97)
            }
            val n = 90 + floor(rand.unit() * 70).toInt()
            val reach = 0.3 + rand.unit() * 0.3
            repeat(n) {
                val a = rand.unit() * TAU
                val d = 0.05 - ln(1 - rand.unit()) * reach * 0.5
                val r = max(0.005, 0.07 * exp(-d * 4) * (0.3 + rand.unit() * 0.9))
                val e = 1 + d * 7 * rand.unit()
                out += Droplet(cx + cos(a) * d, cy + sin(a) * d, r * e, r, a, 0.96)
            }
        }
        return out
    }

    /** Galaxy: stars over the nebula. */
    fun stars(seed: Long): Stars {
        val rand = WaxRandom(seed + 1)
        val dots = List(260) {
            val (x, y) = inDisc(rand, 1.02)
            val r = 0.003 + rand.unit().pow(4) * 0.014
            Droplet(x, y, r, r, 0.0, 0.45 + rand.unit() * 0.5)
        }
        val glows = List(14) {
            val (x, y) = inDisc(rand, 0.98)
            val r = 0.022 + rand.unit() * 0.02
            Droplet(x, y, r, r, 0.0, 1.0)
        }
        return Stars(dots, glows)
    }

    /**
     * Glitter: about 1400 flecks of mixed size and brightness. Each fleck has a tone, 0 (strongest), 1 or 2, that
     * [fleckColor] turns into a tint of the wax: light flecks on dark wax, dark flecks on light wax.
     */
    fun flecks(seed: Long): List<Droplet> {
        val rand = WaxRandom(seed + 2)
        return List(1400) {
            val (x, y) = inDisc(rand, 1.02)
            val r = 0.003 + rand.unit().pow(3) * 0.013
            val k = rand.unit()
            val tone = if (k < 0.45) 0 else if (k < 0.8) 1 else 2
            Droplet(x, y, r, r, 0.0, 0.35 + rand.unit() * 0.6, tone)
        }
    }

    /** The opaque ARGB of a Glitter fleck of [tone] on wax of the [base] color. */
    fun fleckColor(base: VinylColor, tone: Int): Int {
        val rgb = rgb(base)
        val white = doubleArrayOf(255.0, 255.0, 255.0)
        val black = doubleArrayOf(0.0, 0.0, 0.0)
        val c = if (base.light) when (tone) {
            0 -> mix(rgb, black, 0.5)
            1 -> mix(rgb, black, 0.22)
            else -> white
        } else when (tone) {
            0 -> white
            1 -> mix(rgb, white, 0.5)
            else -> mix(rgb, black, 0.4)
        }
        return (0xFF shl 24) or (c[0].toInt() shl 16) or (c[1].toInt() shl 8) or c[2].toInt()
    }

    /** Split: the angle, in radians, of the line between the two colors. The second color is on the far side of it. */
    fun splitAngle(seed: Long): Double = WaxRandom(seed + 3).unit() * TAU

    // --- Marble: domain-warped value noise, thresholded into bands ---

    private fun hash2(ix: Int, iy: Int, s: Int): Double {
        var h = ix * 374761393 + iy * 668265263 + s * 1597334677
        h = (h xor (h ushr 13)) * 1274126177
        h = h xor (h ushr 16)
        return (h.toLong() and 0xFFFFFFFFL).toDouble() / 4294967296.0
    }

    private fun vnoise(x: Double, y: Double, s: Int): Double {
        val ix = floor(x).toInt()
        val iy = floor(y).toInt()
        val fx = x - ix
        val fy = y - iy
        val u = fx * fx * fx * (fx * (fx * 6 - 15) + 10)
        val v = fy * fy * fy * (fy * (fy * 6 - 15) + 10)
        val a = hash2(ix, iy, s)
        val b = hash2(ix + 1, iy, s)
        val c = hash2(ix, iy + 1, s)
        val d = hash2(ix + 1, iy + 1, s)
        return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
    }

    private fun fbm(x: Double, y: Double, s: Int): Double {
        var t = 0.0
        var amp = 0.5
        var f = 1.0
        for (i in 0 until 4) {
            t += amp * vnoise(x * f, y * f, s + i * 31)
            f *= 2
            amp *= 0.5
        }
        return t / 0.9375
    }

    private fun smooth(a: Double, b: Double, x: Double): Double {
        val t = ((x - a) / (b - a)).coerceIn(0.0, 1.0)
        return t * t * (3 - 2 * t)
    }

    private fun mix(a: DoubleArray, b: DoubleArray, t: Double) = DoubleArray(3) { a[it] + (b[it] - a[it]) * t }

    private fun rgb(c: VinylColor) = doubleArrayOf(((c.argb shr 16) and 0xFF).toDouble(), ((c.argb shr 8) and 0xFF).toDouble(), (c.argb and 0xFF).toDouble())

    /**
     * Marble as [n] x [n] ARGB pixels (straight alpha, row by row, top first) covering the square around the disc; draw
     * it clipped to the disc. A Clear [base] stays see-through where the [second] color is absent.
     */
    fun marble(seed: Long, base: VinylColor, second: VinylColor, n: Int = MARBLE_SIZE): IntArray {
        val rand = WaxRandom(seed)
        val s0 = floor(rand.unit() * 1e6).toInt()
        val o = DoubleArray(6) { rand.unit() * 80 }
        val scale = 1.45
        val baseRgb = rgb(base)
        val secRgb = rgb(second)
        val baseAlpha = (base.argb ushr 24) / 255.0
        val veinRgb = if (second.light) mix(secRgb, doubleArrayOf(0.0, 0.0, 0.0), 0.35) else mix(secRgb, doubleArrayOf(255.0, 255.0, 255.0), 0.4)
        val mid = mix(baseRgb, secRgb, 0.5)
        val out = IntArray(n * n)
        for (y in 0 until n) for (x in 0 until n) {
            val px = ((x + 0.5) / n * 2 - 1) * scale
            val py = ((y + 0.5) / n * 2 - 1) * scale
            val qx = fbm(px + o[0], py + o[1], s0)
            val qy = fbm(px + o[2], py + o[3], s0 + 7)
            val rx = fbm(px + 3.2 * qx + o[4], py + 3.2 * qy + 1.7, s0 + 13)
            val ry = fbm(px + 3.2 * qx + 8.3, py + 3.2 * qy + o[5], s0 + 19)
            val f = fbm(px + 3.2 * rx, py + 3.2 * ry, s0 + 29)
            val band = 0.5 + 0.5 * sin((f - 0.5) * TAU * 2.1 + 0.6)
            val t = smooth(0.3, 0.7, band)
            val edge = exp(-((band - 0.5) / 0.09).pow(2))
            var col = mix(baseRgb, secRgb, t)
            col = mix(col, mid, edge * 0.45)
            col = mix(col, veinRgb, exp(-((band - 0.5) / 0.03).pow(2)) * 0.45)
            val alpha = baseAlpha + (1 - baseAlpha) * t
            out[y * n + x] = (Math.round(alpha * 255).toInt() shl 24) or
                (col[0].toInt() shl 16) or (col[1].toInt() shl 8) or col[2].toInt()
        }
        return out
    }

    /**
     * Galaxy nebula as [n] x [n] ARGB pixels, like [marble] but smooth: soft clouds of the [second] color over the [base],
     * with brighter cores. Stars are drawn over it from [stars].
     */
    fun nebula(seed: Long, base: VinylColor, second: VinylColor, n: Int = MARBLE_SIZE): IntArray {
        val rand = WaxRandom(seed)
        val s0 = floor(rand.unit() * 1e6).toInt()
        val o = DoubleArray(6) { rand.unit() * 80 }
        val scale = 1.3
        val baseRgb = rgb(base)
        val secRgb = rgb(second)
        val baseAlpha = (base.argb ushr 24) / 255.0
        val lite = mix(secRgb, doubleArrayOf(255.0, 255.0, 255.0), 0.35)
        val out = IntArray(n * n)
        for (y in 0 until n) for (x in 0 until n) {
            val px = ((x + 0.5) / n * 2 - 1) * scale
            val py = ((y + 0.5) / n * 2 - 1) * scale
            val qx = fbm(px + o[0], py + o[1], s0)
            val qy = fbm(px + o[2], py + o[3], s0 + 7)
            val f = fbm(px + 2.2 * qx + o[4], py + 2.2 * qy + o[5], s0 + 13)
            val t = smooth(0.38, 0.78, f)
            val core = smooth(0.62, 0.9, f)
            var col = mix(baseRgb, secRgb, t)
            col = mix(col, lite, core * 0.5)
            val alpha = baseAlpha + (1 - baseAlpha) * t
            out[y * n + x] = (Math.round(alpha * 255).toInt() shl 24) or
                (col[0].toInt() shl 16) or (col[1].toInt() shl 8) or col[2].toInt()
        }
        return out
    }

    /** The bitmap under a Finish that has one: Marble (veined bands) or Galaxy (soft nebula); null for the others. */
    fun bitmap(finish: Finish?, seed: Long, base: VinylColor, second: VinylColor, n: Int = MARBLE_SIZE): IntArray? = when (finish) {
        Finish.MARBLE -> marble(seed, base, second, n)
        Finish.GALAXY -> nebula(seed, base, second, n)
        else -> null
    }

    private class GlintSpec(val rand: WaxRandom, val count: Int, val minRadius: Double, val radiusSpan: Double)

    /**
     * The glints that shimmer with the tilt: 150 small ones on Glitter, 40 bigger ones (the twinkling stars) on Galaxy,
     * none on any other Finish. They are drawn over the still wax, which does not change.
     */
    fun glints(finish: Finish?, seed: Long): List<Glint> {
        val spec = when (finish) {
            Finish.GLITTER -> GlintSpec(WaxRandom(seed + 4), 150, 0.007, 0.011)
            Finish.GALAXY -> GlintSpec(WaxRandom(seed + 5), 40, 0.012, 0.016)
            else -> return emptyList()
        }
        val rand = spec.rand
        return List(spec.count) {
            val (x, y) = inDisc(rand, 0.97)
            val r = spec.minRadius + rand.unit() * spec.radiusSpan
            val a = (rand.unit() * 2 - 1) * 14
            val b = (rand.unit() * 2 - 1) * 14
            Glint(x, y, r, a, b, rand.unit() * TAU)
        }
    }

    /**
     * How brightly a [glint] flashes, 0 to 1, for a phone tilt of ([tiltX], [tiltY]), each in -1..1. A spiky cosine: a
     * glint is dark most of the time and flashes when the tilt faces its own angle, so a tilting phone makes them twinkle.
     */
    fun glintLevel(glint: Glint, tiltX: Double, tiltY: Double): Double =
        max(0.0, cos(glint.a * tiltX + glint.b * tiltY + glint.phase)).pow(12)
}
