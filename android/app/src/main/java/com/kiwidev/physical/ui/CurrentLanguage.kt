package com.kiwidev.physical.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import com.kiwidev.physical.data.Language

/**
 * The language the UI is rendered in. The chosen language is applied as the app locale, so the
 * configuration already follows it (and recomposes on a live switch); with no choice it is the
 * device language, English unless French. Formatters take this, never the device region.
 */
@Composable
fun currentLanguage(): Language {
    val locales = LocalConfiguration.current.locales
    return Language.forDevice((0 until locales.size()).map { locales[it].language })
}
