package dev.kiwi.vinyl.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import dev.kiwi.vinyl.data.Disc
import dev.kiwi.vinyl.data.Format
import kotlinx.coroutines.launch

@Composable
fun HomeScreen(vm: AppVm, nav: NavHostController) {
    val coll by vm.dao.byList(false).collectAsState(emptyList())
    val wish by vm.dao.byList(true).collectAsState(emptyList())
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Welcome home", style = MaterialTheme.typography.headlineMedium)
        Text("${coll.count { it.format == Format.VINYL }} vinyles · ${coll.count { it.format == Format.CD }} CDs")
        Text("${wish.size} in wishlist")
        Button(onClick = { nav.navigate(R.SCAN) }) { Text("Scan barcode") }
        OutlinedButton(onClick = { nav.edit(vm, Disc()) }) { Text("Add manually") }
    }
}

enum class Sort { ARTIST, ADDED, YEAR }

@Composable
fun ListScreen(vm: AppVm, nav: NavHostController, wishlist: Boolean) {
    val all by vm.dao.byList(wishlist).collectAsState(emptyList())
    var format by remember { mutableStateOf<Format?>(null) }
    var sort by remember { mutableStateOf(Sort.ARTIST) }
    val shown = all.filter { format == null || it.format == format }.let { l ->
        when (sort) {
            Sort.ARTIST -> l
            Sort.ADDED -> l.sortedByDescending { it.addedAt }
            Sort.YEAR -> l.sortedBy { it.year ?: Int.MAX_VALUE }
        }
    }
    Scaffold(floatingActionButton = {
        FloatingActionButton(onClick = { nav.edit(vm, Disc(wishlist = wishlist)) }) { Icon(Icons.Default.Add, "Add") }
    }) { pad ->
        Column(Modifier.padding(pad).padding(horizontal = 16.dp)) {
            Text(if (wishlist) "Ma wishlist" else "Ma collection", style = MaterialTheme.typography.headlineMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(null, Format.CD, Format.VINYL).forEach { f ->
                    FilterChip(format == f, { format = f }, { Text(f?.name ?: "All") })
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Sort.entries.forEach { s -> FilterChip(sort == s, { sort = s }, { Text(s.name.lowercase()) }) }
            }
            DiscList(shown) { nav.edit(vm, it) }
        }
    }
}

@Composable
fun DiscList(items: List<Disc>, onClick: (Disc) -> Unit) {
    if (items.isEmpty()) Text("Nothing here", Modifier.padding(vertical = 16.dp))
    LazyColumn {
        items(items) { d ->
            ListItem(
                modifier = Modifier.clickable { onClick(d) },
                headlineContent = { Text(d.title.ifBlank { "(untitled)" }) },
                supportingContent = {
                    Text(listOfNotNull(d.artist, d.year?.toString(), d.format.name).joinToString(" · ") +
                        (if (d.comment.isNotBlank()) "\n\"${d.comment}\"" else ""))
                },
                trailingContent = { if (d.id != 0L && !d.wishlist) Text("★".repeat(d.rating) + "☆".repeat(5 - d.rating)) },
            )
        }
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
    Column(Modifier.padding(16.dp).verticalScroll(rememberScrollState())) {
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
    headlineContent = { Text(d.title) },
    supportingContent = { Text(listOfNotNull(d.artist, d.year?.toString(), d.format.name).joinToString(" · ")) },
)

@Composable
fun EditScreen(vm: AppVm, nav: NavHostController) {
    var d by remember { mutableStateOf(vm.draft) }
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
        Row {
            (1..5).forEach { i ->
                IconButton({ d = d.copy(rating = if (d.rating == i) 0 else i) }) {
                    Icon(if (i <= d.rating) Icons.Default.Star else Icons.Default.StarBorder, "Rate $i")
                }
            }
        }
        OutlinedTextField(d.comment, { d = d.copy(comment = it) }, Modifier.fillMaxWidth(), label = { Text("Comment") })
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Switch(d.wishlist, { d = d.copy(wishlist = it) }); Text("  In wishlist")
        }
        Button(enabled = d.title.isNotBlank(), onClick = { vm.save(d); nav.popBackStack() }) { Text("Save") }
        if (d.id != 0L) OutlinedButton({ vm.delete(d); nav.popBackStack() }) { Text("Delete") }
    }
}
