package com.kiwidev.physical

import android.app.Application
import com.kiwidev.physical.data.LanguageSettings

class VinylApp : Application() {
    override fun onCreate() {
        super.onCreate()
        LanguageSettings(this).reconcile()
    }
}
