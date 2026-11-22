package com.kiwidev.physical.ui

import androidx.annotation.StringRes
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.HazeStyle
import dev.chrisbanes.haze.HazeTint
import dev.chrisbanes.haze.hazeEffect
import com.kiwidev.physical.R as AppR

/** Content that scrolls under the glass marks itself with `Modifier.hazeSource(LocalHaze.current)`. */
val LocalHaze = staticCompositionLocalOf { HazeState() }

// Blur 14 dp from API 31; below that Haze draws the fallback tint (white 85 %) instead.
private val GlassStyle = HazeStyle(
    backgroundColor = Color.White,
    tints = emptyList(),
    blurRadius = 14.dp,
    noiseFactor = 0f,
    fallbackTint = HazeTint(Color.White.copy(alpha = 0.85f)),
)
private val GlassFill = Brush.linearGradient(listOf(Color.White.copy(alpha = 0.6f), Color(0xFFF0F0F0).copy(alpha = 0.35f)))
private val GlassRim = Brush.verticalGradient(
    0f to Color.White.copy(alpha = 0.95f), 0.5f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.04f),
)

/** Neutral borderless glass: blurred backdrop, 135° white wash, soft drop shadow, inner rim light. */
@Composable
private fun Modifier.glass(shape: Shape): Modifier = this
    .shadow(10.dp, shape, ambientColor = Color.Black.copy(alpha = 0.3f), spotColor = Color.Black.copy(alpha = 0.3f))
    .clip(shape)
    .hazeEffect(LocalHaze.current, GlassStyle)
    .background(GlassFill)
    .border(1.dp, GlassRim, shape)

/** 48 dp glass button (round unless `shape` says otherwise); shrinks to 0.96 while pressed. */
@Composable
fun GlassIconButton(icon: ImageVector, label: String, onClick: () -> Unit, modifier: Modifier = Modifier, shape: Shape = CircleShape) {
    val src = remember { MutableInteractionSource() }
    val pressed by src.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.96f else 1f, tween(150), label = "press")
    Box(
        modifier
            .size(48.dp)
            .graphicsLayer { scaleX = scale; scaleY = scale }
            .glass(shape)
            .clickable(src, indication = null, role = Role.Button, onClick = onClick)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, Modifier.size(44.dp), tint = Color.Unspecified) }
}

private class Tab(val route: String?, @StringRes val labelRes: Int, val icon: ImageVector, val active: ImageVector = icon)

private val pillTabs = listOf(
    Tab(R.PROFILE, AppR.string.tab_profile, Glyphs.Profile, Glyphs.ProfileOn),
    Tab(R.WISH, AppR.string.tab_wishlist, Glyphs.Heart, Glyphs.HeartOn),
    Tab(R.COLL, AppR.string.tab_collection, Glyphs.Disc, Glyphs.DiscOn),
    Tab(R.SEARCH, AppR.string.tab_search, Glyphs.Search, Glyphs.SearchOn),
    Tab(R.HOME, AppR.string.tab_home, Glyphs.Home, Glyphs.HomeOn),
)

/** Vertical glass navigation pill, anchored right. Active tab: Accent fill + Ink outline. */
@Composable
fun GlassNavPill(current: String?, onNavigate: (String) -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier
            .width(52.dp)
            .glass(RoundedCornerShape(26.dp))
            .padding(vertical = 6.dp, horizontal = 4.dp)
            .selectableGroup(),
        verticalArrangement = Arrangement.spacedBy(2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        pillTabs.forEach { t ->
            val on = t.route != null && t.route == current
            val label = stringResource(t.labelRes)
            Box(
                Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .selectable(on, enabled = t.route != null, role = Role.Tab) { t.route?.let(onNavigate) }
                    .semantics { contentDescription = label },
                contentAlignment = Alignment.Center,
            ) { Icon(if (on) t.active else t.icon, null, tint = Color.Unspecified) }
        }
    }
}
