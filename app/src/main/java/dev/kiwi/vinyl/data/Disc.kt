package dev.kiwi.vinyl.data

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow

enum class Format { CD, VINYL }

@Entity
data class Disc(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String = "",
    val artist: String = "",
    val year: Int? = null,
    val format: Format = Format.VINYL,
    val barcode: String? = null,
    val rating: Int = 0,
    val comment: String = "",
    val wishlist: Boolean = false,
    val addedAt: Long = System.currentTimeMillis(),
    val coverUrl: String? = null,
    /** Seen price, euro cents: kept while in the Wishlist, hidden (not cleared) once owned. */
    val seenPrice: Long? = null,
    /** Paid price, euro cents: what the Collection value adds up. */
    val paidPrice: Long? = null,
    /** Vinyl color, null = black. Kept (not cleared) if the Format becomes CD. */
    val vinylColor: VinylColor? = null,
)

@Dao
interface DiscDao {
    @Query("SELECT * FROM Disc WHERE wishlist = :wishlist ORDER BY artist COLLATE NOCASE, year")
    fun byList(wishlist: Boolean): Flow<List<Disc>>

    @Query("SELECT * FROM Disc WHERE title LIKE '%' || :q || '%' OR artist LIKE '%' || :q || '%' ORDER BY artist COLLATE NOCASE")
    fun search(q: String): Flow<List<Disc>>

    @Query("SELECT * FROM Disc WHERE id = :id")
    suspend fun get(id: Long): Disc?

    @Upsert suspend fun upsert(d: Disc): Long
    @Delete suspend fun delete(d: Disc)
}

@Database(entities = [Disc::class], version = 4)
abstract class AppDb : RoomDatabase() {
    abstract fun dao(): DiscDao
    companion object {
        @Volatile private var db: AppDb? = null
        private val V1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) = db.execSQL("ALTER TABLE Disc ADD COLUMN coverUrl TEXT")
        }
        private val V2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE Disc ADD COLUMN seenPrice INTEGER")
                db.execSQL("ALTER TABLE Disc ADD COLUMN paidPrice INTEGER")
            }
        }
        private val V3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) = db.execSQL("ALTER TABLE Disc ADD COLUMN vinylColor TEXT")
        }
        fun get(c: Context) = db ?: synchronized(this) {
            db ?: Room.databaseBuilder(c.applicationContext, AppDb::class.java, "vinyl.db")
                .addMigrations(V1_2, V2_3, V3_4).build().also { db = it }
        }
    }
}
