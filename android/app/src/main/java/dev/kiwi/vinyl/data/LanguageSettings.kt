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

    /** Remember [language] and re-render now: the activity is recreated in the new language. */
    fun choose(language: Language) {
        prefs.edit().putString(KEY, language.tag).apply()
        apply(language)
    }

    /**
     * Brings the stored pick and the app's locale into agreement ([Language.reconcile]): a language picked
     * later in system Settings is synced into the preference instead of being overwritten by it, and a
     * stored pick is put back in force when the system holds no app locale. Called at app start and each
     * time the activity is created, so a system pick made while the process lives is synced too.
     */
    fun reconcile() {
        val r = Language.reconcile(stored(), appLocales(), deviceLanguages(), systemKeepsAppLocale = Build.VERSION.SDK_INT >= 33)
        if (r.stored != stored()) {
            prefs.edit().apply { r.stored?.let { putString(KEY, it.tag) } ?: remove(KEY) }.apply()
        }
        r.apply?.let(::apply)
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

    /** The locale set for this app (by [choose] or system Settings), language codes; empty when none. */
    private fun appLocales(): List<String> =
        if (Build.VERSION.SDK_INT >= 33) {
            appContext.getSystemService(LocaleManager::class.java).applicationLocales.languages()
        } else {
            AppCompatDelegate.getApplicationLocales().let { l -> (0 until l.size()).map { l[it]!!.language } }
        }

    private fun deviceLanguages(): List<String> = Resources.getSystem().configuration.locales.languages()

    private fun LocaleList.languages() = (0 until size()).map { get(it).language }

    private companion object {
        const val KEY = "language"
    }
}
