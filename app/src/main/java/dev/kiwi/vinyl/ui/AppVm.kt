package dev.kiwi.vinyl.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import dev.kiwi.vinyl.data.AppDb
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.MusicBrainz
import kotlinx.coroutines.launch

class AppVm(app: Application) : AndroidViewModel(app) {
    val dao = AppDb.get(app).dao()

    /** Disc being edited (new draft or existing). */
    var draft: Disc = Disc()

    fun save(d: Disc) = viewModelScope.launch { dao.upsert(d) }
    fun delete(d: Disc) = viewModelScope.launch { dao.delete(d) }
    suspend fun load(id: Long) = dao.get(id)
    suspend fun lookupBarcode(code: String) = MusicBrainz.byBarcode(code)
    suspend fun searchCatalog(q: String) = MusicBrainz.search(q)
}
