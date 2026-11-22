package com.kiwidev.physical.ui

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.kiwidev.physical.data.AppDb
import com.kiwidev.physical.data.Disc
import com.kiwidev.physical.data.Discogs
import com.kiwidev.physical.data.Language
import com.kiwidev.physical.data.LanguageSettings
import com.kiwidev.physical.data.MusicBrainz
import com.kiwidev.physical.data.ProfileName
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AppVm(app: Application) : AndroidViewModel(app) {
    val dao = AppDb.get(app).dao()

    /** Disc being edited (new draft or existing). */
    var draft: Disc = Disc()

    private val prefs = app.getSharedPreferences("profile", Context.MODE_PRIVATE)
    private val _name = MutableStateFlow(prefs.getString("name", null).orEmpty())
    /** Profile name; empty = unset. */
    val name: StateFlow<String> = _name

    fun setName(raw: String) {
        val n = ProfileName.clean(raw)
        prefs.edit().apply { if (n.isEmpty()) remove("name") else putString("name", n) }.apply()
        _name.value = n
    }

    private val languageSettings = LanguageSettings(app)

    /** Picks [l] as the app language; the activity is recreated in it, so the UI reads it back from the configuration. */
    fun setLanguage(l: Language) = languageSettings.choose(l)

    fun save(d: Disc) = viewModelScope.launch { dao.upsert(d) }
    fun delete(d: Disc) = viewModelScope.launch { dao.delete(d) }
    suspend fun load(id: Long) = dao.get(id)
    /** Discogs first; MusicBrainz when Discogs finds nothing or fails. */
    suspend fun lookupBarcode(code: String) = Discogs.byBarcode(code).ifEmpty { MusicBrainz.byBarcode(code) }
    suspend fun searchCatalog(q: String) = Discogs.search(q).ifEmpty { MusicBrainz.search(q) }
}
