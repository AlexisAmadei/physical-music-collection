package dev.kiwi.vinyl.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.*
import androidx.navigation.navArgument
import dev.chrisbanes.haze.rememberHazeState
import dev.kiwi.vinyl.data.Disc

object R { const val HOME = "home"; const val COLL = "collection"; const val WISH = "wishlist"; const val SEARCH = "search"; const val SCAN = "scan"; const val EDIT = "edit" }

/** Routes that show the floating glass chrome (nav pill + scan / add buttons). */
private val chromeRoutes = setOf(R.HOME, R.COLL, R.WISH, R.SEARCH)

/** Open edit form on a draft (new or existing disc). */
fun NavHostController.edit(vm: AppVm, d: Disc) { vm.draft = d; navigate(R.EDIT) }

@Composable
fun App() {
    val nav = rememberNavController()
    val vm: AppVm = viewModel()
    val route = nav.currentBackStackEntryAsState().value?.destination?.route?.substringBefore("?")
    CompositionLocalProvider(LocalHaze provides rememberHazeState()) {
        Box(Modifier.fillMaxSize().background(Palette.Surface)) {
            NavHost(nav, R.HOME, Modifier.fillMaxSize()) {
                composable(R.HOME) { HomeScreen(vm, nav) }
                composable(R.COLL) { CollectionScreen(vm, nav) }
                composable(R.WISH) { WishlistScreen(vm, nav) }
                composable(R.SEARCH + "?nf={nf}", listOf(navArgument("nf") { defaultValue = "" })) { SearchScreen(vm, nav, it.arguments?.getString("nf") ?: "") }
                composable(R.SCAN) { Box(Modifier.safeDrawingPadding()) { ScanScreen(vm, nav) } }
                composable(R.EDIT) { Box(Modifier.safeDrawingPadding()) { EditScreen(vm, nav) } }
            }
            if (route in chromeRoutes) Chrome(route, vm, nav)
        }
    }
}

/** Glass pill on the right, Scanner and "+" bottom-left; positions from the 412 × 917 dp frame. */
@Composable
private fun BoxScope.Chrome(route: String?, vm: AppVm, nav: NavHostController) {
    val bottom = chromeBottom()
    GlassNavPill(
        route,
        onNavigate = { r -> nav.navigate(r) { popUpTo(R.HOME); launchSingleTop = true } },
        Modifier.align(Alignment.BottomEnd).padding(end = 14.dp, bottom = bottom + 50.dp),
    )
    Row(Modifier.align(Alignment.BottomStart).padding(start = 21.dp, bottom = bottom), horizontalArrangement = Arrangement.spacedBy(11.dp)) {
        GlassIconButton(Glyphs.Scan, "Scanner un code-barres", onClick = { nav.navigate(R.SCAN) })
        if (route == R.WISH) {
            GlassIconButton(Glyphs.Plus, "Ajouter à la wishlist", onClick = { nav.edit(vm, Disc(wishlist = true)) })
        } else Box {
            var adding by remember { mutableStateOf(false) }
            GlassIconButton(Glyphs.Plus, "Ajouter un disque", onClick = { adding = true })
            AddChoices(adding, { adding = false }, vm, nav)
        }
    }
}
