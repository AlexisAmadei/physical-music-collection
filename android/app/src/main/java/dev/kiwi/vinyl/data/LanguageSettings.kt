package dev.kiwi.vinyl.data

import android.app.LocaleManager
import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.os.LocaleList
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat

/**
 * The one place that reads and writes the `language` preference. Absent = follow the device.
 * The choice is applied as the app's locale (appcompat per-app locales), so every string
 * resource, and later every formatter, follows it with no other plumbing.
 */
class LanguageSettings(context: Context) {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences("settings", Context.MODE_PRIVATE)

    /** What the user picked, or null when they never did. */
    fun stored(): Language? = Language.fromTag(prefs.getString(KEY, null))

    /** The language the app shows: the stored choice, else the device language, else English. */
    fun effective(): Language = stored() ?: Language.forDevice(deviceLanguages())

    /** Remember [language] and re-render now: the activity is recreated in the new language. */
    fun choose(language: Language) {
        prefs.edit().putString(KEY, language.tag).apply()
        apply(language)
    }

    /** At app start: put a stored choice back in force. With none, the device language applies untouched. */
    fun applyStored() {
        stored()?.let(::apply)
    }

    /**
     * API 33+: the system LocaleManager, which is what appcompat calls too, but appcompat silently
     * does nothing before the first AppCompat activity exists, and we apply at app start.
     * Older: appcompat applies it to its activities and recreates them.
     */
    private fun apply(language: Language) {
        if (Build.VERSION.SDK_INT >= 33) {
            appContext.getSystemService(LocaleManager::class.java).applicationLocales = LocaleList.forLanguageTags(language.tag)
        } else {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(language.tag))
        }
    }

    private fun deviceLanguages(): List<String> {
        val locales = Resources.getSystem().configuration.locales
        return (0 until locales.size()).map { locales[it].language }
    }

    private companion object {
        const val KEY = "language"
    }
}
