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
import com.kiwidev.physical.data.waxSeed
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
                    FinishSwatch(f, color, d.secondColor ?: f?.defaultSecondColor, d.waxSeed, Modifier.size(40.dp))
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

/** A round preview of a Finish in the form, drawn like the wax of the Disc: same colors, same pattern. */
@Composable
fun FinishSwatch(finish: Finish?, color: VinylColor, second: VinylColor?, seed: Long, modifier: Modifier = Modifier) {
    val bitmap = rememberWaxBitmap(finish, color, second, seed, n = 64)
    Canvas(modifier.clip(CircleShape).border(1.dp, Palette.Line, CircleShape)) {
        drawWax(color, finish, second, seed, bitmap)
    }
}
