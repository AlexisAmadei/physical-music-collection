package com.kiwidev.physical.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.kiwidev.physical.R as AppR
import com.kiwidev.physical.data.Disc
import com.kiwidev.physical.data.Finish
import com.kiwidev.physical.data.VinylColor
import com.kiwidev.physical.data.shownSecondColor
import com.kiwidev.physical.data.withFinish

/**
 * The Finish choice of the form, under the Vinyl color: Solid then each Finish as a round preview with its name, the
 * picked one ringed. A Finish that uses a Second color adds a row of dots for it. Shown on vinyl Discs with a Vinyl color.
 */
@Composable
fun FinishField(d: Disc, onChange: (Disc) -> Unit) {
    val color = d.vinylColor ?: return
    Text(stringResource(AppR.string.form_finish), style = MaterialTheme.typography.labelLarge)
    Row(
        Modifier.horizontalScroll(rememberScrollState()).selectableGroup(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        (listOf<Finish?>(null) + Finish.entries).forEach { f ->
            val on = f == d.finish
            val name = f.displayName()
            Column(
                Modifier
                    .selectable(on, role = Role.RadioButton) { onChange(d.withFinish(f)) }
                    .semantics { contentDescription = name }
                    .padding(vertical = 4.dp, horizontal = 2.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(
                    Modifier.size(52.dp).border(2.dp, if (on) Palette.Ink else Color.Transparent, CircleShape).padding(4.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    FinishSwatch(f, color, d.secondColor ?: f?.defaultSecondColor, Modifier.size(40.dp))
                }
                Text(name, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
    if (d.finish?.usesSecondColor == true) {
        Text(stringResource(AppR.string.form_second_color), style = MaterialTheme.typography.labelLarge)
        Row(
            Modifier.horizontalScroll(rememberScrollState()).selectableGroup(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            VinylColor.secondChoices.forEach { c ->
                val on = c == d.shownSecondColor
                val colorName = c.displayName()
                Box(
                    Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .selectable(on, role = Role.RadioButton) { onChange(d.copy(secondColor = c)) }
                        .semantics { contentDescription = colorName }
                        .border(2.dp, if (on) Palette.Ink else Color.Transparent, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(24.dp).clip(CircleShape).background(Color(c.argb)).border(1.dp, Palette.Line, CircleShape))
                }
            }
        }
    }
}

/**
 * A round hint of a Finish in the form. A stand-in until the wax drawing exists: Split is two halves, Marble, Splatter
 * and Galaxy are the Vinyl color with spots of the Second color, Glitter has silver flecks.
 */
@Composable
fun FinishSwatch(finish: Finish?, color: VinylColor, second: VinylColor?, modifier: Modifier = Modifier) {
    Canvas(modifier.clip(CircleShape).border(1.dp, Palette.Line, CircleShape)) {
        drawRect(Color(color.argb))
        val c2 = Color((second ?: VinylColor.WHITE).argb)
        val w = size.width
        when (finish) {
            null -> Unit
            Finish.SPLIT -> drawRect(c2, Offset(w / 2, 0f), Size(w / 2, size.height))
            Finish.MARBLE, Finish.SPLATTER, Finish.GALAXY -> {
                drawCircle(c2, w * 0.22f, Offset(w * 0.32f, w * 0.34f))
                drawCircle(c2, w * 0.14f, Offset(w * 0.70f, w * 0.62f))
                drawCircle(c2, w * 0.08f, Offset(w * 0.40f, w * 0.78f))
            }
            Finish.GLITTER -> listOf(0.25f to 0.3f, 0.6f to 0.22f, 0.72f to 0.55f, 0.35f to 0.65f, 0.55f to 0.8f).forEach { (x, y) ->
                drawCircle(Color(0xFFE6E8EC), w * 0.045f, Offset(w * x, w * y))
            }
        }
    }
}
