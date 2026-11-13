package dev.kiwi.vinyl.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.*
import androidx.navigation.navArgument
import dev.kiwi.vinyl.data.Disc

object R { const val HOME = "home"; const val COLL = "collection"; const val WISH = "wishlist"; const val SEARCH = "search"; const val SCAN = "scan"; const val EDIT = "edit" }

private val tabs = listOf(
    Triple(R.HOME, "Home", Icons.Default.Home),
    Triple(R.COLL, "Collection", Icons.Default.Album),
    Triple(R.WISH, "Wishlist", Icons.Default.Favorite),
    Triple(R.SEARCH, "Search", Icons.Default.Search),
    Triple(R.SCAN, "Scan", Icons.Default.QrCodeScanner),
)

/** Open edit form on a draft (new or existing disc). */
fun NavHostController.edit(vm: AppVm, d: Disc) { vm.draft = d; navigate(R.EDIT) }

@Composable
fun App() {
    val nav = rememberNavController()
    val vm: AppVm = viewModel()
    val route = nav.currentBackStackEntryAsState().value?.destination?.route
    Scaffold(bottomBar = {
        NavigationBar {
            tabs.forEach { (r, label, icon: ImageVector) ->
                NavigationBarItem(selected = route?.substringBefore("?") == r, label = { Text(label) }, icon = { Icon(icon, label) },
                    onClick = { nav.navigate(r) { popUpTo(R.HOME); launchSingleTop = true } })
            }
        }
    }) { pad ->
        NavHost(nav, R.HOME, Modifier.padding(pad)) {
            composable(R.HOME) { HomeScreen(vm, nav) }
            composable(R.COLL) { ListScreen(vm, nav, wishlist = false) }
            composable(R.WISH) { ListScreen(vm, nav, wishlist = true) }
            composable(R.SEARCH + "?nf={nf}", listOf(navArgument("nf") { defaultValue = "" })) { SearchScreen(vm, nav, it.arguments?.getString("nf") ?: "") }
            composable(R.SCAN) { ScanScreen(vm, nav) }
            composable(R.EDIT) { EditScreen(vm, nav) }
        }
    }
}
