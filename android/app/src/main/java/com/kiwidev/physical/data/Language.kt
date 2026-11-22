package com.kiwidev.physical.data

/** The language of the app chrome. Only English and French; user-entered text is never translated. */
enum class Language(val tag: String) {
    EN("en"),
    FR("fr");

    companion object {
        /** A stored tag as a Language; absent or unknown = no choice made. */
        fun fromTag(tag: String?): Language? = entries.firstOrNull { it.tag == tag }

        /** The first of the device's languages (language codes, most preferred first) the app has; English when none. */
        fun forDevice(languages: List<String>): Language =
            languages.firstNotNullOfOrNull { fromTag(it) } ?: EN

        /**
         * Settles the language from the three places it lives: the [stored] pick, the app's own locale
         * ([appLocales], language codes: what Android renders with, and what system Settings "App
         * languages" edits) and the [deviceLanguages].
         *
         * - An app locale is the newest word: it is what is shown, and the stored pick follows it. This
         *   covers a pick made in system Settings after one made in the app.
         * - With no app locale and [systemKeepsAppLocale] (API 33+: the system persists it), none means
         *   the user reset it to the device default: the stored pick is dropped.
         * - With no app locale and no system persistence (older Android), the stored pick is put back
         *   in force ([Resolution.apply]); with no pick either, the device language (English fallback).
         */
        fun reconcile(
            stored: Language?, appLocales: List<String>, deviceLanguages: List<String>, systemKeepsAppLocale: Boolean,
        ): Resolution {
            appLocales.firstNotNullOfOrNull { fromTag(it) }?.let { return Resolution(it, stored = it, apply = null) }
            if (systemKeepsAppLocale || stored == null) return Resolution(forDevice(deviceLanguages), stored = null, apply = null)
            return Resolution(stored, stored = stored, apply = stored)
        }
    }

    /** [effective]: the language shown. [stored]: what the preference should hold. [apply]: to set as app locale, if any. */
    data class Resolution(val effective: Language, val stored: Language?, val apply: Language?)
}
