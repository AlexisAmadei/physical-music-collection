package com.kiwidev.physical.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The unit text ("tr/min" / "rpm") is a string resource; see StringResourcesTest. */
class SpeedTest {
    @Test fun aNewDiscHasNoSpeed() {
        assertNull(Disc().speed)
        assertNull(Disc().shownSpeed)
    }

    @Test fun vinylShowsItsSpeed() {
        assertEquals(Speed.RPM_33, Disc(format = Format.VINYL, speed = Speed.RPM_33).shownSpeed)
        assertEquals(Speed.RPM_45, Disc(format = Format.VINYL, speed = Speed.RPM_45).shownSpeed)
    }

    @Test fun vinylWithoutSpeedShowsNothing() {
        assertNull(Disc(format = Format.VINYL).shownSpeed)
    }

    @Test fun tappingTheSelectedSpeedClearsIt() {
        assertEquals(Speed.RPM_33, (null as Speed?).tapped(Speed.RPM_33))
        assertEquals(Speed.RPM_45, Speed.RPM_33.tapped(Speed.RPM_45))
        assertNull(Speed.RPM_45.tapped(Speed.RPM_45))
    }

    @Test fun aCdKeepsItsSpeedButHidesIt() {
        val cd = Disc(format = Format.CD, speed = Speed.RPM_45)
        assertEquals(Speed.RPM_45, cd.speed)
        assertNull(cd.shownSpeed)
        // Switching the Format back to vinyl restores it.
        assertEquals(Speed.RPM_45, cd.copy(format = Format.VINYL).shownSpeed)
    }

    @Test fun speedShowsInCollectionAndWishlist() {
        assertEquals(Speed.RPM_33, Disc(wishlist = false, speed = Speed.RPM_33).shownSpeed)
        assertEquals(Speed.RPM_33, Disc(wishlist = true, speed = Speed.RPM_33).shownSpeed)
    }
}
