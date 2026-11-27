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

    @Test fun speckleAndFleckCountsAreFixed() {
        assertEquals(160, WaxPattern.speckles(1).size)
        assertEquals(420, WaxPattern.flecks(1).size)
        assertTrue(WaxPattern.speckles(1).all { it.x * it.x + it.y * it.y <= 1.05 * 1.05 })
    }

    @Test fun splitAngleIsWithinAFullTurn() {
        repeat(50) { val a = WaxPattern.splitAngle(it.toLong()); assertTrue(a >= 0 && a < 2 * Math.PI) }
    }

    @Test fun marbleIsTheSameEveryTimeAndOpaqueOnSolidWax() {
        val a = WaxPattern.marble(9, VinylColor.RED, VinylColor.BLACK, 24)
        assertEquals(24 * 24, a.size)
        assertTrue(a.contentEquals(WaxPattern.marble(9, VinylColor.RED, VinylColor.BLACK, 24)))
        assertTrue(a.all { (it ushr 24) == 255 })
    }

    @Test fun marbleMixesBothColorsAndDiffersPerSeed() {
        val a = WaxPattern.marble(9, VinylColor.RED, VinylColor.WHITE, 48)
        val reds = a.count { ((it shr 16) and 0xFF) > 0xA0 && ((it shr 8) and 0xFF) < 0x80 }
        val whites = a.count { ((it shr 8) and 0xFF) > 0xD0 }
        assertTrue("both colors show: $reds red, $whites white", reds > 48 * 48 / 10 && whites > 48 * 48 / 10)
        assertTrue(!a.contentEquals(WaxPattern.marble(10, VinylColor.RED, VinylColor.WHITE, 48)))
    }

    @Test fun marbleOnClearWaxIsSeeThroughWhereTheSecondColorIsAbsent() {
        val a = WaxPattern.marble(9, VinylColor.CLEAR, VinylColor.RED, 48)
        val alphas = a.map { it ushr 24 }
        assertTrue(alphas.min() in 0x8A..0x8E)
        assertTrue(alphas.max() > 0xF0)
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
