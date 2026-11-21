package dev.kiwi.vinyl

import android.app.Application
import dev.kiwi.vinyl.data.LanguageSettings

class VinylApp : Application() {
    override fun onCreate() {
        super.onCreate()
        LanguageSettings(this).applyStored()
    }
}
