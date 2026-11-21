package dev.kiwi.vinyl.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SpeedTest {
    @Test fun aNewDiscHasNoSpeed() {
        assertNull(Disc().speed)
        assertNull(Disc().shownSpeed)
        assertNull(Disc().speedLabel)
    }

    @Test fun speedIsShownAsRevolutionsPerMinute() {
        assertEquals("33 tr/min", Disc(format = Format.VINYL, speed = Speed.RPM_33).speedLabel)
        assertEquals("45 tr/min", Disc(format = Format.VINYL, speed = Speed.RPM_45).speedLabel)
    }

    @Test fun vinylWithoutSpeedShowsNothing() {
        assertNull(Disc(format = Format.VINYL).speedLabel)
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
        assertNull(cd.speedLabel)
        // Switching the Format back to vinyl restores it.
        val back = cd.copy(format = Format.VINYL)
        assertEquals(Speed.RPM_45, back.shownSpeed)
        assertEquals("45 tr/min", back.speedLabel)
    }

    @Test fun speedShowsInCollectionAndWishlist() {
        assertEquals("33 tr/min", Disc(wishlist = false, speed = Speed.RPM_33).speedLabel)
        assertEquals("33 tr/min", Disc(wishlist = true, speed = Speed.RPM_33).speedLabel)
    }
}
