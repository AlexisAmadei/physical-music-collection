package com.kiwidev.physical

import android.graphics.Color
import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import com.kiwidev.physical.data.LanguageSettings
import com.kiwidev.physical.ui.App
import com.kiwidev.physical.ui.PhysicalTheme

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // The design is light-only: dark system-bar icons over the white surface, whatever the system theme.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.argb(0xe6, 0xff, 0xff, 0xff), Color.argb(0x80, 0x1b, 0x1b, 0x1b)),
        )
        // A language picked in system Settings while the process lived: sync it into the stored pick.
        LanguageSettings(this).reconcile()
        super.onCreate(savedInstanceState)
        setContent { PhysicalTheme { App() } }
    }
}
