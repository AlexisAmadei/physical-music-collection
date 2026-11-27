package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FinishTest {
    private val red = Disc(format = Format.VINYL, vinylColor = VinylColor.RED)

    @Test fun marbleSplatterSplitAndGalaxyUseASecondColorButSolidAndGlitterDoNot() {
        assertEquals(
            setOf(Finish.MARBLE, Finish.SPLATTER, Finish.SPLIT, Finish.GALAXY),
            Finish.entries.filter { it.usesSecondColor }.toSet(),
        )
        assertFalse(Finish.GLITTER.usesSecondColor)
    }

    @Test fun secondColorStartsAsWhiteAndBlackForSplit() {
        assertEquals(VinylColor.WHITE, Finish.MARBLE.defaultSecondColor)
        assertEquals(VinylColor.WHITE, Finish.SPLATTER.defaultSecondColor)
        assertEquals(VinylColor.WHITE, Finish.GALAXY.defaultSecondColor)
        assertEquals(VinylColor.BLACK, Finish.SPLIT.defaultSecondColor)
        assertNull(Finish.GLITTER.defaultSecondColor)
    }

    @Test fun aDiscIsSolidWhenNoFinishIsSet() {
        assertNull(red.shownFinish)
        assertNull(red.shownSecondColor)
        assertNull(Disc().finish)
        assertNull(Disc().secondColor)
    }

    @Test fun pickingAFinishThatUsesASecondColorPreselectsIt() {
        assertEquals(VinylColor.WHITE, red.withFinish(Finish.MARBLE).secondColor)
        assertEquals(VinylColor.BLACK, red.withFinish(Finish.SPLIT).secondColor)
        assertNull(red.withFinish(Finish.GLITTER).secondColor)
    }

    @Test fun pickingAFinishKeepsASecondColorAlreadyChosen() {
        val picked = red.withFinish(Finish.MARBLE).copy(secondColor = VinylColor.BLACK).withFinish(Finish.SPLATTER)
        assertEquals(VinylColor.BLACK, picked.secondColor)
    }

    @Test fun goingBackToSolidKeepsTheSecondColorHiddenAndItComesBackWithTheNextFinish() {
        val solid = red.withFinish(Finish.MARBLE).copy(secondColor = VinylColor.TEAL).withFinish(null)
        assertNull(solid.finish)
        assertEquals(VinylColor.TEAL, solid.secondColor)
        assertNull(solid.shownSecondColor)
        assertEquals(VinylColor.TEAL, solid.withFinish(Finish.GALAXY).shownSecondColor)
    }

    @Test fun glitterHidesAKeptSecondColor() {
        val glitter = red.withFinish(Finish.MARBLE).copy(secondColor = VinylColor.TEAL).withFinish(Finish.GLITTER)
        assertEquals(VinylColor.TEAL, glitter.secondColor)
        assertNull(glitter.shownSecondColor)
    }

    @Test fun turningTheVinylColorOffClearsTheFinishAndTheSecondColor() {
        val off = red.withFinish(Finish.MARBLE).withVinylColor(null)
        assertNull(off.vinylColor)
        assertNull(off.finish)
        assertNull(off.secondColor)
    }

    @Test fun pickingAnotherVinylColorKeepsTheFinishAndTheSecondColor() {
        val blue = red.withFinish(Finish.SPLATTER).copy(secondColor = VinylColor.GOLD).withVinylColor(VinylColor.BLUE)
        assertEquals(VinylColor.BLUE, blue.vinylColor)
        assertEquals(Finish.SPLATTER, blue.finish)
        assertEquals(VinylColor.GOLD, blue.secondColor)
    }

    @Test fun aCDKeepsItsFinishAndSecondColorHiddenAndVinylShowsThemAgain() {
        val cd = red.withFinish(Finish.MARBLE).copy(format = Format.CD)
        assertEquals(Finish.MARBLE, cd.finish)
        assertEquals(VinylColor.WHITE, cd.secondColor)
        assertNull(cd.shownFinish)
        assertNull(cd.shownSecondColor)

        val back = cd.copy(format = Format.VINYL)
        assertEquals(Finish.MARBLE, back.shownFinish)
        assertEquals(VinylColor.WHITE, back.shownSecondColor)
    }

    @Test fun aFinishNeedsAVinylColorToShow() {
        // The form never builds this, but a stored Disc could: no Vinyl color means plain black wax.
        val orphan = Disc(format = Format.VINYL, finish = Finish.MARBLE, secondColor = VinylColor.WHITE)
        assertNull(orphan.shownFinish)
        assertNull(orphan.shownSecondColor)
        assertTrue(red.withFinish(Finish.MARBLE).shownFinish != null)
    }

    @Test fun aSecondColorIsNeverShownWithoutItsFinishEvenIfStoredNull() {
        // A Finish that uses a Second color but has none stored shows the Finish default.
        val noSecond = red.copy(finish = Finish.SPLIT, secondColor = null)
        assertEquals(VinylColor.BLACK, noSecond.shownSecondColor)
    }
}
