package com.kiwidev.physical.data

import androidx.room.migration.Migration
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/** Opens a real version 4 database (from app/schemas/4.json) and upgrades it to the current version. */
class MigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(), AppDb::class.java, emptyList(), FrameworkSQLiteOpenHelperFactory(),
    )

    private val from4: Array<Migration> = AppDb.MIGRATIONS.filter { it.startVersion >= 4 }.toTypedArray()

    @Test fun existingDiscsOpenWithNoSpeedAfterUpgradingFromVersion4() {
        helper.createDatabase(DB, 4).apply {
            execSQL(
                "INSERT INTO Disc (id, title, artist, year, format, barcode, rating, comment, wishlist, addedAt, coverUrl, seenPrice, paidPrice, vinylColor) " +
                    "VALUES (1, 'Kind of Blue', 'Miles Davis', 1959, 'VINYL', NULL, 5, 'great', 0, 0, NULL, NULL, 2500, 'RED')",
            )
            close()
        }

        val db = helper.runMigrationsAndValidate(DB, 5, true, *from4)

        db.query("SELECT title, paidPrice, vinylColor, speed FROM Disc WHERE id = 1").use { c ->
            assertTrue(c.moveToFirst())
            assertEquals("Kind of Blue", c.getString(0))
            assertEquals(2500L, c.getLong(1))
            assertEquals("RED", c.getString(2))
            assertTrue(c.isNull(3))
        }
    }

    @Test fun speedCanBeStoredAfterMigration() {
        helper.createDatabase(DB, 4).close()
        val db = helper.runMigrationsAndValidate(DB, 5, true, *from4)
        db.execSQL("INSERT INTO Disc (title, artist, format, rating, comment, wishlist, addedAt, speed) VALUES ('t', 'a', 'VINYL', 0, '', 0, 0, 'RPM_45')")
        db.query("SELECT speed FROM Disc").use { c ->
            assertTrue(c.moveToFirst())
            assertEquals("RPM_45", c.getString(0))
        }
    }

    private companion object { const val DB = "migration-test" }
}
