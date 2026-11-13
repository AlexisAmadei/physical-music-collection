package dev.kiwi.vinyl.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import dev.kiwi.vinyl.data.AppDb
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.Discogs
import dev.kiwi.vinyl.data.MusicBrainz
import kotlinx.coroutines.launch

class AppVm(app: Application) : AndroidViewModel(app) {
    val dao = AppDb.get(app).dao()

    /** Disc being edited (new draft or existing). */
    var draft: Disc = Disc()

    fun save(d: Disc) = viewModelScope.launch { dao.upsert(d) }
    fun delete(d: Disc) = viewModelScope.launch { dao.delete(d) }
    suspend fun load(id: Long) = dao.get(id)
    /** Discogs first; MusicBrainz when Discogs finds nothing or fails. */
    suspend fun lookupBarcode(code: String) = Discogs.byBarcode(code).ifEmpty { MusicBrainz.byBarcode(code) }
    suspend fun searchCatalog(q: String) = Discogs.search(q).ifEmpty { MusicBrainz.search(q) }
}
