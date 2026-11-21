package dev.kiwi.vinyl.ui

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.OptIn
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.navigation.NavHostController
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import dev.kiwi.vinyl.R as AppR
import dev.kiwi.vinyl.data.Disc
import java.util.concurrent.Executors

@Composable
fun ScanScreen(vm: AppVm, nav: NavHostController) {
    val ctx = LocalContext.current
    var granted by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED)
    }
    val ask = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted = it }
    LaunchedEffect(Unit) { if (!granted) ask.launch(Manifest.permission.CAMERA) }

    var code by remember { mutableStateOf<String?>(null) }

    // Barcode found -> lookup -> prefilled form, or fallback to search.
    LaunchedEffect(code) {
        val c = code ?: return@LaunchedEffect
        val hit = vm.lookupBarcode(c).firstOrNull()
        if (hit != null) nav.edit(vm, hit)
        else { vm.draft = Disc(barcode = c); nav.navigate(R.SEARCH + "?nf=" + Uri.encode(c)) { popUpTo(R.SCAN) { inclusive = true } } }
    }

    Box(Modifier.fillMaxSize()) {
        when {
            !granted -> Text(stringResource(AppR.string.scan_camera_needed), Modifier.align(Alignment.Center))
            code != null -> Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(); Text(stringResource(AppR.string.scan_looking_up, code ?: ""))
            }
            else -> CameraPreview { if (code == null) code = it }
        }
        OutlinedButton({ nav.edit(vm, Disc(barcode = code)) }, Modifier.align(Alignment.BottomCenter).padding(16.dp)) {
            Text(stringResource(AppR.string.scan_enter_manually))
        }
    }
}

@OptIn(ExperimentalGetImage::class)
@Composable
private fun CameraPreview(onCode: (String) -> Unit) {
    val ctx = LocalContext.current
    val owner = LocalLifecycleOwner.current
    val scanner = remember { BarcodeScanning.getClient() }
    val exec = remember { Executors.newSingleThreadExecutor() }
    DisposableEffect(Unit) { onDispose { exec.shutdown(); scanner.close() } }
    AndroidView(modifier = Modifier.fillMaxSize(), factory = { c ->
        PreviewView(c).also { view ->
            val future = ProcessCameraProvider.getInstance(c)
            future.addListener({
                val provider = future.get()
                val preview = Preview.Builder().build().also { it.surfaceProvider = view.surfaceProvider }
                val analysis = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                analysis.setAnalyzer(exec) { proxy ->
                    val img = proxy.image
                    if (img == null) { proxy.close(); return@setAnalyzer }
                    scanner.process(InputImage.fromMediaImage(img, proxy.imageInfo.rotationDegrees))
                        .addOnSuccessListener { list -> list.firstNotNullOfOrNull { it.rawValue }?.let(onCode) }
                        .addOnCompleteListener { proxy.close() }
                }
                provider.unbindAll()
                provider.bindToLifecycle(owner, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis)
            }, ContextCompat.getMainExecutor(ctx))
        }
    })
}
