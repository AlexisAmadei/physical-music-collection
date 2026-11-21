package dev.kiwi.vinyl.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import coil.compose.AsyncImage
import dev.chrisbanes.haze.hazeSource
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.Format
import dev.kiwi.vinyl.data.Price
import dev.kiwi.vinyl.data.ProfileName
import dev.kiwi.vinyl.data.Speed
import dev.kiwi.vinyl.data.VinylColor
import dev.kiwi.vinyl.data.shownVinylColor
import dev.kiwi.vinyl.data.tapped
import dev.kiwi.vinyl.data.CollectionValue
import dev.kiwi.vinyl.data.collectionValue
import kotlinx.coroutines.launch

@Composable
fun HomeScreen(vm: AppVm, nav: NavHostController) {
    val coll by vm.dao.byList(false).collectAsState(null)
    val discs = coll?.sortedByDescending { it.addedAt } ?: return
    Box(Modifier.fillMaxSize()) {
        if (discs.isEmpty()) {
            var adding by remember { mutableStateOf(false) }
            EmptyState(
                "Scanne un code-barres ou cherche un album pour commencer.", "Ajouter mon premier disque",
                onAdd = { adding = true },
                Modifier.align(Alignment.CenterStart).padding(start = 20.dp, end = 72.dp),
            ) { AddChoices(adding, { adding = false }, vm, nav) }
        } else {
            CoverWheel(discs, onOpen = { nav.edit(vm, it) }, Modifier.hazeSource(LocalHaze.current))
        }
        Text(
            "Welcome home...", style = Type.Welcome,
            modifier = Modifier.align(Alignment.BottomEnd).padding(end = 20.dp, bottom = chromeBottom() + 8.dp),
        )
    }
}

enum class Sort { ADDED, YEAR }

@Composable
fun CollectionScreen(vm: AppVm, nav: NavHostController) {
    val all by vm.dao.byList(false).collectAsState(null)
    var format by rememberSaveable { mutableStateOf<Format?>(null) }
    var sort by rememberSaveable { mutableStateOf(Sort.ADDED) }
    val list = all ?: return
    val shown = remember(list, format, sort) {
        list.filter { format == null || it.format == format }.sortedWith(
            when (sort) {
                Sort.ADDED -> compareByDescending { it.addedAt }
                Sort.YEAR -> compareByDescending<Disc> { it.year ?: Int.MIN_VALUE }.thenByDescending { it.addedAt }
            }
        )
    }
    CoverGrid("Ma collection", rowGap = 28.dp, headerGap = 35.dp, header = {
        Row(
            Modifier.padding(top = 16.dp).height(38.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically,
        ) {
            FormatFilter(format, { format = it }, Modifier.padding(start = 5.dp))
            SortToggle(sort, { sort = it })
        }
    }) {
        if (shown.isEmpty()) item(span = { GridItemSpan(maxLineSpan) }) {
            var adding by remember { mutableStateOf(false) }
            EmptyState(
                "Scanne un code-barres ou cherche un album pour commencer.", "Ajouter mon premier disque",
                onAdd = { adding = true }, Modifier.padding(top = 120.dp - 28.dp),
            ) { AddChoices(adding, { adding = false }, vm, nav) }
        }
        items(shown, key = { it.id }) { d -> CoverCard(d, onClick = { nav.edit(vm, d) }) }
    }
}

@Composable
fun WishlistScreen(vm: AppVm, nav: NavHostController) {
    val all by vm.dao.byList(true).collectAsState(null)
    val list = all ?: return
    CoverGrid("Ma wishlist", rowGap = 12.dp, headerGap = 21.dp) {
        if (list.isEmpty()) item(span = { GridItemSpan(maxLineSpan) }) {
            EmptyState(
                "Ajoute les disques que tu cherches.", "Ajouter à la wishlist",
                onAdd = { nav.edit(vm, Disc(wishlist = true)) }, Modifier.padding(top = 120.dp - 12.dp),
            )
        }
        items(list, key = { it.id }) { d -> CoverCard(d, showMeta = false, onClick = { nav.edit(vm, d) }) }
    }
}

/** The user's own screen: the Profile card, then the Collection value by Format. */
@Composable
fun ProfileScreen(vm: AppVm, nav: NavHostController) {
    val all by vm.dao.byList(false).collectAsState(null)
    val name by vm.name.collectAsState()
    var editing by rememberSaveable { mutableStateOf(false) }
    val list = all ?: return
    val value = remember(list) { collectionValue(list) }
    Column(
        Modifier.fillMaxSize().hazeSource(LocalHaze.current).verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = screenTop(), bottom = 119.dp + chromeBottom()),
    ) {
        Text("MON PROFIL", style = Type.Display)
        ProfileCard(name, value.total, list.size, onEditName = { editing = true }, Modifier.padding(top = 24.dp))
        if (list.isEmpty()) {
            var adding by remember { mutableStateOf(false) }
            EmptyState(
                "Scanne un code-barres ou cherche un album pour commencer.", "Ajouter mon premier disque",
                onAdd = { adding = true }, Modifier.padding(top = 35.dp),
            ) { AddChoices(adding, { adding = false }, vm, nav) }
        } else {
            ValueByFormat(value, Modifier.padding(top = 35.dp))
        }
    }
    if (editing) NameSheet(name, onDone = { vm.setName(it); editing = false }, onDismiss = { editing = false })
}

@Composable
private fun ValueByFormat(v: CollectionValue, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text("Par format", Modifier.padding(bottom = 4.dp), style = Type.Label, color = Palette.Muted)
        listOf("CD" to v.cd, "Vinyle" to v.vinyl).forEach { (label, cents) ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(label, style = Type.Body)
                Text(Price.format(cents), style = Type.Body, fontWeight = FontWeight.Medium)
            }
        }
        if (v.unpriced > 0) {
            Text(
                if (v.unpriced == 1) "1 disque sans prix" else "${v.unpriced} disques sans prix",
                Modifier.padding(top = 12.dp), style = Type.Body, color = Palette.Muted,
            )
        }
    }
}

/** One field for the Profile name. Blank clears it. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NameSheet(current: String, onDone: (String) -> Unit, onDismiss: () -> Unit) {
    var text by rememberSaveable { mutableStateOf(current) }
    val focus = remember { FocusRequester() }
    ModalBottomSheet(onDismiss, containerColor = Palette.Surface) {
        Column(Modifier.padding(start = 20.dp, end = 20.dp, bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text("Ton nom", style = Type.Title)
            OutlinedTextField(
                text, { text = it.take(ProfileName.MAX) }, Modifier.fillMaxWidth().focusRequester(focus),
                singleLine = true, supportingText = { Text("${text.length} / ${ProfileName.MAX}") },
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { onDone(text) }),
            )
            Button(
                { onDone(text) }, Modifier.height(48.dp).align(Alignment.End), shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(Palette.Ink, Color.White),
                contentPadding = PaddingValues(horizontal = 24.dp),
            ) { Text("OK", style = Type.Body, fontWeight = FontWeight.Medium) }
        }
    }
    LaunchedEffect(Unit) { focus.requestFocus() }
}

/** Two equal columns, 20 dp margins and gutter; the uppercase title scrolls with the grid. */
@Composable
private fun CoverGrid(title: String, rowGap: Dp, headerGap: Dp, header: @Composable () -> Unit = {}, content: LazyGridScope.() -> Unit) {
    LazyVerticalGrid(
        GridCells.Fixed(2),
        Modifier.fillMaxSize().hazeSource(LocalHaze.current),
        contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = screenTop(), bottom = 119.dp + chromeBottom()),
        horizontalArrangement = Arrangement.spacedBy(20.dp),
        verticalArrangement = Arrangement.spacedBy(rowGap),
    ) {
        item(span = { GridItemSpan(maxLineSpan) }) {
            Column(Modifier.padding(bottom = headerGap - rowGap)) {
                Text(title.uppercase(), style = Type.Display)
                header()
            }
        }
        content()
    }
}

fun Disc.a11yLabel() =
    listOfNotNull(
        title.ifBlank { "Sans titre" }, artist.ifBlank { null },
        if (format == Format.CD) "CD" else shownVinylColor?.let { "Vinyle couleur ${it.label.lowercase()}" } ?: "Vinyle",
        year?.toString(),
    )
        .joinToString(", ")

/** Cover art, or a neutral disc placeholder while loading / when there is none. */
@Composable
fun Cover(url: String?, modifier: Modifier = Modifier) {
    Box(modifier.background(Palette.Placeholder), contentAlignment = Alignment.Center) {
        Icon(Glyphs.Disc, null, tint = Palette.Line)
        if (url != null) AsyncImage(url, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
    }
}

/** Square-ish cover, title (+ rating and optional comment when [showMeta]). Tap → detail. */
@Composable
private fun CoverCard(d: Disc, onClick: () -> Unit, showMeta: Boolean = true) {
    var flipped by rememberSaveable(d.id) { mutableStateOf(false) }
    Column {
        FlipCover(d, flipped, onFlip = { flipped = !flipped }, onEdit = onClick, Modifier.fillMaxWidth().aspectRatio(176f / 177f))
        Row(
            Modifier.padding(top = 8.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(d.title.ifBlank { "Sans titre" }, Modifier.weight(1f), style = Type.Title, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (showMeta) StarRating(d.rating)
        }
        if (showMeta && d.comment.isNotBlank()) {
            Text("“${d.comment}”", Modifier.padding(top = 6.dp), style = Type.Body, color = Palette.Muted)
        }
    }
}

/** Read-only 0..5 stars, one semantic node. */
@Composable
fun StarRating(rating: Int, size: Dp = 15.dp) {
    Row(
        Modifier.clearAndSetSemantics { contentDescription = if (rating > 0) "Note : $rating sur 5" else "Non noté" },
        horizontalArrangement = Arrangement.spacedBy(1.dp),
    ) {
        (1..5).forEach { i -> Icon(Glyphs.Star, null, Modifier.size(size), tint = if (i <= rating) Palette.Ink else Palette.Line) }
    }
}

/** CD / Vinyle chips. Tap selects; tapping the active chip goes back to all formats. */
@Composable
private fun FormatFilter(selected: Format?, onChange: (Format?) -> Unit, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        listOf(Format.CD to "CD", Format.VINYL to "Vinyle").forEach { (f, label) ->
            val on = selected == f
            Box(
                Modifier
                    .height(38.dp)
                    .defaultMinSize(minWidth = 44.dp)
                    .clip(RoundedCornerShape(19.dp))
                    .background(if (on) Palette.Ink else Color.Transparent)
                    .toggleable(on, role = Role.Switch) { onChange(if (on) null else f) }
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(label, style = Type.Chip, color = Palette.Accent, fontWeight = if (on) FontWeight.Medium else FontWeight.Normal)
            }
        }
    }
}

/** Date d’ajout (default) / Année. Active label: 600, underlined 4 dp below the text. */
@Composable
private fun SortToggle(sort: Sort, onChange: (Sort) -> Unit) {
    Row(Modifier.selectableGroup(), horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        listOf(Sort.ADDED to "Date d’ajout", Sort.YEAR to "Année").forEach { (s, label) ->
            val on = sort == s
            var baseline by remember { mutableFloatStateOf(0f) }
            Box(
                Modifier
                    .height(44.dp)
                    .selectable(on, role = Role.RadioButton) { onChange(s) }
                    .padding(start = 8.dp, end = if (s == Sort.YEAR) 0.dp else 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label, style = Type.Label, fontWeight = if (on) FontWeight.SemiBold else FontWeight.Normal,
                    onTextLayout = { baseline = it.firstBaseline },
                    modifier = Modifier.drawBehind {
                        if (on) {
                            val y = baseline + 4.dp.toPx()
                            drawLine(Palette.Ink, Offset(0f, y), Offset(size.width, y), strokeWidth = 1.dp.toPx())
                        }
                    },
                )
            }
        }
    }
}

/** "Rien ici pour l’instant." + hint + filled Ink button. [anchored] is drawn next to the button (e.g. a menu). */
@Composable
private fun EmptyState(hint: String, action: String, onAdd: () -> Unit, modifier: Modifier = Modifier, anchored: @Composable () -> Unit = {}) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Rien ici pour l’instant.", style = Type.Welcome)
        Text(hint, style = Type.Body, color = Palette.Muted)
        Box {
            Button(
                onAdd, Modifier.height(48.dp), shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(Palette.Ink, Color.White),
                contentPadding = PaddingValues(horizontal = 20.dp),
            ) { Text(action, style = Type.Body, fontWeight = FontWeight.Medium) }
            anchored()
        }
    }
}

/** The "+" choice: scan, catalog search or manual entry. */
@Composable
fun AddChoices(expanded: Boolean, onDismiss: () -> Unit, vm: AppVm, nav: NavHostController) {
    DropdownMenu(expanded, onDismiss) {
        DropdownMenuItem({ Text("Scanner un code-barres") }, { onDismiss(); nav.navigate(R.SCAN) })
        DropdownMenuItem({ Text("Rechercher un album") }, { onDismiss(); nav.navigate(R.SEARCH) { launchSingleTop = true } })
        DropdownMenuItem({ Text("Saisie manuelle") }, { onDismiss(); nav.edit(vm, Disc()) })
    }
}

@Composable
/** notFound = barcode that failed lookup; kept on the disc picked here. */
fun SearchScreen(vm: AppVm, nav: NavHostController, notFound: String) {
    var q by remember { mutableStateOf("") }
    var remote by remember { mutableStateOf<List<Disc>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val local by vm.dao.search(q).collectAsState(emptyList())
    // Floating nav chrome stays visible here: keep the last rows clear of it.
    Column(
        Modifier.fillMaxSize().hazeSource(LocalHaze.current).verticalScroll(rememberScrollState())
            .safeDrawingPadding().padding(16.dp).padding(bottom = 124.dp)
    ) {
        if (notFound.isNotBlank()) Text("Barcode $notFound not found. Search by name.", color = MaterialTheme.colorScheme.error)
        OutlinedTextField(q, { q = it }, Modifier.fillMaxWidth(), label = { Text("Looking for something?") })
        Text("My discs", style = MaterialTheme.typography.titleMedium)
        Column { (if (q.isBlank()) emptyList() else local).forEach { d -> DiscRow(d) { nav.edit(vm, d) } } }
        Button(enabled = q.isNotBlank() && !loading, onClick = {
            scope.launch { loading = true; remote = vm.searchCatalog(q); loading = false }
        }) { Text(if (loading) "Searching…" else "Search catalog") }
        remote.forEach { d -> DiscRow(d) { nav.edit(vm, d.copy(barcode = notFound.ifBlank { d.barcode })) } }
        if (notFound.isNotBlank()) OutlinedButton({ nav.edit(vm, Disc(barcode = notFound, title = q)) }) { Text("Add manually") }
    }
}

@Composable
private fun DiscRow(d: Disc, onClick: () -> Unit) = ListItem(
    modifier = Modifier.clickable(onClick = onClick),
    leadingContent = {
        Box(Modifier.size(56.dp)) {
            Cover(d.coverUrl, Modifier.matchParentSize().clip(RoundedCornerShape(4.dp)))
            ColorBandOf(d)
        }
    },
    headlineContent = { Text(d.title) },
    supportingContent = { Text(listOfNotNull(d.artist, d.year?.toString(), d.format.name).joinToString(" · ")) },
)

/** "Vinyle couleur" switch; when on, a row of 24 dp dots, the picked one ringed. Off = black (null). */
@Composable
private fun VinylColorField(color: VinylColor?, onChange: (VinylColor?) -> Unit) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("Vinyle couleur")
        Switch(color != null, { onChange(if (it) VinylColor.RED else null) })
    }
    if (color == null) return
    Row(
        Modifier.horizontalScroll(rememberScrollState()).selectableGroup(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        VinylColor.entries.forEach { c ->
            val on = c == color
            Box(
                Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .selectable(on, role = Role.RadioButton) { onChange(c) }
                    .semantics { contentDescription = c.label }
                    .border(2.dp, if (on) Palette.Ink else Color.Transparent, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Box(Modifier.size(24.dp).clip(CircleShape).background(Color(c.argb)).border(1.dp, Palette.Line, CircleShape))
            }
        }
    }
}

/** "33 | 45" segmented control, nothing selected at first. Tapping the selected one clears it (null). */
@Composable
private fun SpeedField(speed: Speed?, onChange: (Speed?) -> Unit) {
    Text("Vitesse", style = MaterialTheme.typography.labelLarge)
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        Speed.entries.forEachIndexed { i, s ->
            SegmentedButton(
                selected = speed == s,
                onClick = { onChange(speed.tapped(s)) },
                shape = SegmentedButtonDefaults.itemShape(i, Speed.entries.size),
            ) {
                // Read "33 tr/min", not a bare "33" (iOS: accessibilityLabel(speed.label)). The button is a selectable
                // radio, so the screen reader already announces whether it is selected.
                Text(s.rpm.toString(), Modifier.clearAndSetSemantics { contentDescription = "${s.rpm} tr/min" })
            }
        }
    }
}

@Composable
fun EditScreen(vm: AppVm, nav: NavHostController) {
    var d by remember { mutableStateOf(vm.draft) }
    // Raw text so "12," survives while typing; parsed into the Disc on save.
    var seen by remember { mutableStateOf(Price.input(vm.draft.seenPrice)) }
    var paid by remember { mutableStateOf(Price.input(vm.draft.paidPrice)) }
    Column(Modifier.padding(16.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(if (d.id == 0L) "Add disc" else "Edit disc", style = MaterialTheme.typography.headlineSmall)
        OutlinedTextField(d.title, { d = d.copy(title = it) }, Modifier.fillMaxWidth(), label = { Text("Title") })
        OutlinedTextField(d.artist, { d = d.copy(artist = it) }, Modifier.fillMaxWidth(), label = { Text("Artist") })
        OutlinedTextField(d.year?.toString() ?: "", { d = d.copy(year = it.toIntOrNull()) }, Modifier.fillMaxWidth(),
            label = { Text("Year") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
        OutlinedTextField(d.barcode ?: "", { d = d.copy(barcode = it.ifBlank { null }) }, Modifier.fillMaxWidth(), label = { Text("Barcode") })
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Format.entries.forEach { f -> FilterChip(d.format == f, { d = d.copy(format = f) }, { Text(f.name) }) }
        }
        if (d.format == Format.VINYL) {
            VinylColorField(d.vinylColor) { d = d.copy(vinylColor = it) }
            SpeedField(d.speed) { d = d.copy(speed = it) }
        }
        Row {
            (1..5).forEach { i ->
                IconButton({ d = d.copy(rating = if (d.rating == i) 0 else i) }) {
                    Icon(if (i <= d.rating) Icons.Default.Star else Icons.Default.StarBorder, "Rate $i")
                }
            }
        }
        OutlinedTextField(d.comment, { d = d.copy(comment = it) }, Modifier.fillMaxWidth(), label = { Text("Comment") })
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        ) {
            Text("In wishlist")
            Switch(d.wishlist, {
                // Bought: suggest the seen price as the paid price, still editable.
                if (!it && paid.isBlank() && Price.isValid(seen)) paid = seen
                d = d.copy(wishlist = it)
            })
        }
        // One field at a time: Seen price in the Wishlist, Paid price in the Collection.
        val price = if (d.wishlist) seen else paid
        OutlinedTextField(
            price, { if (d.wishlist) seen = it else paid = it }, Modifier.fillMaxWidth(),
            label = { Text(if (d.wishlist) "Prix vu" else "Prix payé") },
            suffix = { Text("€") }, singleLine = true, isError = !Price.isValid(price),
            supportingText = { if (!Price.isValid(price)) Text("Exemple : 12,50") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(enabled = d.title.isNotBlank() && Price.isValid(price), onClick = {
                // The hidden field cannot be fixed from here: keep its stored value if it is malformed.
                fun cents(text: String, stored: Long?) = if (Price.isValid(text)) Price.parse(text) else stored
                vm.save(d.copy(seenPrice = cents(seen, d.seenPrice), paidPrice = cents(paid, d.paidPrice)))
                nav.popBackStack()
            }) { Text("Save") }
            if (d.id != 0L) OutlinedButton({ vm.delete(d); nav.popBackStack() }) { Text("Delete") }
        }
    }
}
