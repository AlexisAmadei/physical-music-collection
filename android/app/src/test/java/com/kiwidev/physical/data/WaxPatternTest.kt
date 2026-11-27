package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WaxPatternTest {
    @Test fun splitMix64MatchesTheReferenceSequence() {
        // The published SplitMix64 outputs for seed 0. iOS WaxPatternTests pins the same values.
        val r = WaxRandom(0)
        assertEquals(0xE220A8397B1DCDAFuL.toLong(), r.next())
        assertEquals(0x6E789E6AA1B965F4uL.toLong(), r.next())
        assertEquals(0x06C45D188009454FuL.toLong(), r.next())
    }

    @Test fun unitIsInZeroToOne() {
        val r = WaxRandom(42)
        repeat(1000) { val u = r.unit(); assertTrue(u >= 0.0 && u < 1.0) }
    }

    @Test fun theSeedOfADiscIsStableAndDiffersBetweenDiscs() {
        assertEquals(Disc(addedAt = 1_700_000_000_000).waxSeed, Disc(addedAt = 1_700_000_000_000).waxSeed)
        assertNotEquals(Disc(addedAt = 1_700_000_000_000).waxSeed, Disc(addedAt = 1_700_000_000_001).waxSeed)
        // Editing a Disc keeps its pattern: nothing but addedAt feeds the seed.
        assertEquals(Disc(addedAt = 5).waxSeed, Disc(addedAt = 5, title = "x", vinylColor = VinylColor.RED).waxSeed)
    }

    @Test fun theSeedForAGivenTimeIsPinnedForCrossPlatformParity() {
        // Computed independently with a Python SplitMix64; iOS WaxPatternTests pins the same value.
        assertEquals(940689255921423875L, Disc(addedAt = 1_700_000_000_000).waxSeed)
    }

    @Test fun splatterIsTheSameEveryTimeAndDiffersPerSeed() {
        assertEquals(WaxPattern.splatter(7), WaxPattern.splatter(7))
        assertNotEquals(WaxPattern.splatter(7), WaxPattern.splatter(8))
    }

    @Test fun splatterThrowsABurstFromEachImpactPoint() {
        val drops = WaxPattern.splatter(7)
        // 4 to 6 impacts, each 5 to 8 core blobs and 90 to 159 droplets.
        assertTrue(drops.size in 4 * 95..6 * 167)
        assertTrue(drops.all { it.rx > 0 && it.ry > 0 && it.alpha in 0.9..1.0 })
        // Droplets thrown away from the core are stretched along their flight.
        assertTrue(drops.any { it.rx > it.ry * 1.5 })
    }

    @Test fun mostSplatterStaysOnTheDisc() {
        val drops = WaxPattern.splatter(123)
        val on = drops.count { it.x * it.x + it.y * it.y <= 1.2 * 1.2 }
        assertTrue(on > drops.size * 0.85)
    }

    @Test fun starAndFleckCountsAreFixed() {
        assertEquals(260, WaxPattern.stars(1).dots.size)
        assertEquals(14, WaxPattern.stars(1).glows.size)
        assertEquals(1400, WaxPattern.flecks(1).size)
        assertTrue(WaxPattern.stars(1).dots.all { it.x * it.x + it.y * it.y <= 1.05 * 1.05 })
        assertTrue(WaxPattern.flecks(1).all { it.x * it.x + it.y * it.y <= 1.05 * 1.05 })
    }

    @Test fun starsAndFlecksAreTheSameEveryTime() {
        assertEquals(WaxPattern.flecks(3), WaxPattern.flecks(3))
        assertEquals(WaxPattern.stars(3).dots, WaxPattern.stars(3).dots)
        assertNotEquals(WaxPattern.flecks(3), WaxPattern.flecks(4))
    }

    @Test fun starsAreMostlyFineWithAFewBigGlows() {
        val s = WaxPattern.stars(5)
        assertTrue(s.dots.count { it.rx < 0.006 } > s.dots.size / 2)
        assertTrue(s.glows.all { it.rx in 0.022..0.042 })
    }

    @Test fun fleckTonesAreSpreadAcrossTheThreeTones() {
        val tones = WaxPattern.flecks(5).groupingBy { it.tone }.eachCount()
        assertEquals(setOf(0, 1, 2), tones.keys)
        assertTrue(tones.getValue(0) > tones.getValue(2))
    }

    @Test fun fleckTintsAreLightOnDarkWaxAndDarkOnLightWax() {
        fun lum(argb: Int) = ((argb shr 16) and 0xFF) + ((argb shr 8) and 0xFF) + (argb and 0xFF)
        // Dark wax: the strongest flecks are white; light wax: they are darker than the wax.
        assertEquals(0xFFFFFFFF.toInt(), WaxPattern.fleckColor(VinylColor.BLUE, 0))
        assertTrue(lum(WaxPattern.fleckColor(VinylColor.WHITE, 0)) < lum(VinylColor.WHITE.argb.toInt()))
        assertTrue(lum(WaxPattern.fleckColor(VinylColor.YELLOW, 1)) < lum(VinylColor.YELLOW.argb.toInt()))
        assertEquals(0xFFFFFFFF.toInt(), WaxPattern.fleckColor(VinylColor.YELLOW, 2))
        assertTrue(lum(WaxPattern.fleckColor(VinylColor.RED, 2)) < lum(VinylColor.RED.argb.toInt()))
        assertTrue(WaxPattern.fleckColor(VinylColor.TEAL, 1) ushr 24 == 0xFF)
    }

    @Test fun nebulaIsSoftOpaqueAndTheSameEveryTime() {
        val a = WaxPattern.nebula(9, VinylColor.BLUE, VinylColor.BLACK, 32)
        assertEquals(32 * 32, a.size)
        assertTrue(a.contentEquals(WaxPattern.nebula(9, VinylColor.BLUE, VinylColor.BLACK, 32)))
        assertTrue(a.all { (it ushr 24) == 255 })
        assertTrue(!a.contentEquals(WaxPattern.nebula(10, VinylColor.BLUE, VinylColor.BLACK, 32)))
        // Soft: next to each other, pixels differ little (marble has sharp bands).
        val steps = (0 until 32 * 31).map { i -> val p = a[i + i / 31]; val q = a[i + i / 31 + 1]; kotlin.math.abs(((p shr 16) and 0xFF) - ((q shr 16) and 0xFF)) }
        assertTrue(steps.max() < 40)
    }

    @Test fun nebulaMixesBothColors() {
        val a = WaxPattern.nebula(9, VinylColor.BLUE, VinylColor.BLACK, 48)
        val dark = a.count { ((it shr 16) and 0xFF) < 0x20 && (it and 0xFF) < 0x40 }
        val blue = a.count { (it and 0xFF) > 0x90 && ((it shr 16) and 0xFF) < 0x50 }
        assertTrue("both show: $dark dark, $blue blue", dark > 48 * 48 / 20 && blue > 48 * 48 / 20)
    }

    @Test fun nebulaOnClearWaxIsSeeThroughWhereTheSecondColorIsAbsent() {
        val alphas = WaxPattern.nebula(9, VinylColor.CLEAR, VinylColor.RED, 48).map { it ushr 24 }
        assertTrue(alphas.min() in 0x8A..0x95)
        assertTrue(alphas.max() > 0xE0)
    }

    @Test fun bitmapIsMarbleForMarbleNebulaForGalaxyAndNullOtherwise() {
        assertTrue(WaxPattern.bitmap(Finish.MARBLE, 9, VinylColor.RED, VinylColor.WHITE, 16)!!.contentEquals(WaxPattern.marble(9, VinylColor.RED, VinylColor.WHITE, 16)))
        assertTrue(WaxPattern.bitmap(Finish.GALAXY, 9, VinylColor.RED, VinylColor.WHITE, 16)!!.contentEquals(WaxPattern.nebula(9, VinylColor.RED, VinylColor.WHITE, 16)))
        assertEquals(null, WaxPattern.bitmap(Finish.SPLATTER, 9, VinylColor.RED, VinylColor.WHITE, 16))
        assertEquals(null, WaxPattern.bitmap(null, 9, VinylColor.RED, VinylColor.WHITE, 16))
    }

    @Test fun nebulaStarsAndFlecksArePinnedForCrossPlatformParity() {
        // Also asserted by iOS WaxPatternTests (nebula pixels within 1 per channel).
        val seed = 0x1234_5678_9ABCL
        val n = WaxPattern.nebula(seed, VinylColor.BLUE, VinylColor.BLACK, 16)
        assertEquals(
            listOf(0xFF29559CL, 0xFF285398L, 0xFF192539L, 0xFF192230L, 0xFF244780L),
            listOf(0, 17, 100, 135, 255).map { n[it].toLong() and 0xFFFFFFFFL },
        )
        val st = WaxPattern.stars(seed)
        assertEquals(-0.6076736162442895, st.dots[0].x, 1e-9)
        assertEquals(-0.5869105169175586, st.dots[0].y, 1e-9)
        assertEquals(0.005999525691160388, st.dots[0].rx, 1e-9)
        assertEquals(0.6857312517606784, st.dots[0].alpha, 1e-9)
        assertEquals(0.33211123641401147, st.dots.last().x, 1e-9)
        assertEquals(0.0031537245436594687, st.dots.last().rx, 1e-9)
        assertEquals(-0.040921805961647455, st.glows[0].x, 1e-9)
        assertEquals(0.03673884539194255, st.glows[0].rx, 1e-9)
        assertEquals(0.6750497501233313, st.glows.last().x, 1e-9)
        assertEquals(0.034548589046788966, st.glows.last().rx, 1e-9)
        val fl = WaxPattern.flecks(seed)
        assertEquals(-0.5084313018175756, fl[0].x, 1e-9)
        assertEquals(0.009172563331896023, fl[0].rx, 1e-9)
        assertEquals(0.6517783316081485, fl[0].alpha, 1e-9)
        assertEquals(0, fl[0].tone)
        assertEquals(0.616497619115278, fl[700].y, 1e-9)
        assertEquals(0.34199837017293205, fl.last().x, 1e-9)
        assertEquals(1, fl.last().tone)
        assertEquals(
            listOf(0xFFFFFFFFL, 0xFFE39195L, 0xFF781519L, 0xFF796426L, 0xFFBC9C3BL, 0xFFFFFFFFL),
            (0..2).map { WaxPattern.fleckColor(VinylColor.RED, it).toLong() and 0xFFFFFFFFL } +
                (0..2).map { WaxPattern.fleckColor(VinylColor.YELLOW, it).toLong() and 0xFFFFFFFFL },
        )
    }

    @Test fun marblePixelsArePinnedForCrossPlatformParity() {
        // Golden values, also asserted by iOS WaxPatternTests (within 1 per channel: sin and exp may differ in the last bit).
        val p = WaxPattern.marble(0x1234_5678_9ABCL, VinylColor.BLUE, VinylColor.WHITE, 16)
        assertEquals(256, p.size)
        assertEquals(
            listOf(0xFFE7E8E9L, 0xFFF3F1EDL, 0xFFF3F1EDL, 0xFF2B5BA8L, 0xFF406AAFL),
            listOf(0, 17, 100, 135, 255).map { p[it].toLong() and 0xFFFFFFFFL },
        )
    }

    @Test fun splatterIsPinnedForCrossPlatformParity() {
        // Also asserted by iOS WaxPatternTests.
        val d = WaxPattern.splatter(0x1234_5678_9ABCL)
        assertEquals(514, d.size)
        assertEquals(0.18925281250478643, d[0].x, 1e-9)
        assertEquals(0.028500420131112356, d[0].rx, 1e-9)
        assertEquals(0.97, d[0].alpha, 0.0)
        assertEquals(-0.9869534417692565, d[100].y, 1e-9)
        assertEquals(4.1255971454634714, d[100].rot, 1e-9)
        assertEquals(0.4386496446218519, d.last().x, 1e-9)
        assertEquals(0.020505143576469913, d.last().ry, 1e-9)
    }
}
