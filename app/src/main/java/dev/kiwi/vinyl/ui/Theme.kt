package dev.kiwi.vinyl.ui

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.max
import androidx.compose.ui.unit.sp
import dev.kiwi.vinyl.R as AppR

/** Design tokens ("Physical" handoff v1). Reference frame 412 × 917 dp. */
object Palette {
    val Ink = Color(0xFF241111)
    val Accent = Color(0xFFFF8181)
    val Muted = Color(0xFF797979)
    val Line = Color(0xFFD9D9D9)
    val Surface = Color.White
    val Thumb = Color.Black
    val Placeholder = Color(0xFFEEEEEE)
    val Tint = Color(0xFFF6F4F4)
}

/** Provisional: the Figma font is unknown. Swap it here only. */
val AppFont = FontFamily(
    Font(AppR.font.lexend_regular, FontWeight.Normal),
    Font(AppR.font.lexend_medium, FontWeight.Medium),
    Font(AppR.font.lexend_semibold, FontWeight.SemiBold),
    Font(AppR.font.lexend_bold, FontWeight.Bold),
)

object Type {
    val Display = TextStyle(fontFamily = AppFont, fontSize = 32.sp, lineHeight = 36.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.5.sp)
    val Title = TextStyle(fontFamily = AppFont, fontSize = 20.sp, lineHeight = 24.sp, fontWeight = FontWeight.Bold)
    val Welcome = Title.copy(lineHeight = 28.sp, letterSpacing = (-0.2).sp)
    val Body = TextStyle(fontFamily = AppFont, fontSize = 16.sp, lineHeight = 22.sp)
    val Chip = TextStyle(fontFamily = AppFont, fontSize = 14.sp)
    val Label = TextStyle(fontFamily = AppFont, fontSize = 13.sp)
}

/** Top of screen → title: 44 dp, but never under the status bar. */
@Composable
fun screenTop(): Dp = max(44.dp, WindowInsets.statusBars.asPaddingValues().calculateTopPadding() + 12.dp)

/** Bottom of screen → floating buttons: 21 dp, but never under the navigation bar. */
@Composable
fun chromeBottom(): Dp = max(21.dp, WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding())

private val typography = Typography().run {
    fun TextStyle.f() = copy(fontFamily = AppFont)
    Typography(
        displayLarge.f(), displayMedium.f(), displaySmall.f(),
        headlineLarge.f(), headlineMedium.f(), headlineSmall.f(),
        titleLarge.f(), titleMedium.f(), titleSmall.f(),
        bodyLarge.f(), bodyMedium.f(), bodySmall.f(),
        labelLarge.f(), labelMedium.f(), labelSmall.f(),
    )
}

private val colors = lightColorScheme(
    primary = Palette.Ink, onPrimary = Color.White,
    primaryContainer = Palette.Accent, onPrimaryContainer = Palette.Ink,
    secondary = Palette.Accent, onSecondary = Palette.Ink,
    secondaryContainer = Palette.Tint, onSecondaryContainer = Palette.Ink,
    background = Palette.Surface, onBackground = Palette.Ink,
    surface = Palette.Surface, onSurface = Palette.Ink,
    surfaceVariant = Palette.Tint, onSurfaceVariant = Palette.Muted,
    surfaceContainerLowest = Color.White, surfaceContainerLow = Color.White, surfaceContainer = Color.White,
    surfaceContainerHigh = Palette.Tint, surfaceContainerHighest = Color(0xFFEFEAEA),
    outline = Palette.Muted, outlineVariant = Palette.Line,
)

@Composable
fun PhysicalTheme(content: @Composable () -> Unit) = MaterialTheme(colorScheme = colors, typography = typography, content = content)
