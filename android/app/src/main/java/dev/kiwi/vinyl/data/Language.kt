package dev.kiwi.vinyl.data

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

        /** The stored choice wins; with none, follow the device (French) and fall back to English. */
        fun resolve(stored: Language?, deviceLanguage: String): Language =
            stored ?: if (deviceLanguage == FR.tag) FR else EN
    }
}
