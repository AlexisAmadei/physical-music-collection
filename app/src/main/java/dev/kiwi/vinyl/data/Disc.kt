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

@Database(entities = [Disc::class], version = 2)
abstract class AppDb : RoomDatabase() {
    abstract fun dao(): DiscDao
    companion object {
        @Volatile private var db: AppDb? = null
        private val V1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) = db.execSQL("ALTER TABLE Disc ADD COLUMN coverUrl TEXT")
        }
        fun get(c: Context) = db ?: synchronized(this) {
            db ?: Room.databaseBuilder(c.applicationContext, AppDb::class.java, "vinyl.db")
                .addMigrations(V1_2).build().also { db = it }
        }
    }
}
