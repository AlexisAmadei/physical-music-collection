plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.devtools.ksp")
}
import java.util.Properties

// Discogs app credentials: local.properties (git-ignored) or env vars in CI. Blank = anonymous search.
val localProps = Properties().apply { rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use(::load) }
fun secret(prop: String, env: String) = localProps.getProperty(prop) ?: System.getenv(env) ?: ""

android {
    namespace = "dev.kiwi.vinyl"
    compileSdk = 35
    defaultConfig {
        applicationId = "dev.kiwi.vinyl"
        minSdk = 26
        targetSdk = 35
        versionCode = 5
        versionName = "1.2.0"
        buildConfigField("String", "DISCOGS_KEY", "\"${secret("discogs.key", "DISCOGS_KEY")}\"")
        buildConfigField("String", "DISCOGS_SECRET", "\"${secret("discogs.secret", "DISCOGS_SECRET")}\"")
    }
    // Stable release key: same signer every build, so new APKs install as updates.
    signingConfigs {
        create("release") {
            val store = secret("signing.storeFile", "SIGNING_STORE_FILE")
            if (store.isNotBlank()) {
                storeFile = file(store)
                storePassword = secret("signing.storePassword", "SIGNING_STORE_PASSWORD")
                keyAlias = secret("signing.keyAlias", "SIGNING_KEY_ALIAS")
                keyPassword = secret("signing.keyPassword", "SIGNING_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release").takeIf { it.storeFile != null }
        }
    }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true; buildConfig = true }
}
dependencies {
    val bom = platform("androidx.compose:compose-bom:2025.06.01")
    implementation(bom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.navigation:navigation-compose:2.9.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.1")
    implementation("androidx.room:room-runtime:2.7.2")
    implementation("androidx.room:room-ktx:2.7.2")
    ksp("androidx.room:room-compiler:2.7.2")
    implementation("androidx.camera:camera-camera2:1.4.2")
    implementation("androidx.camera:camera-lifecycle:1.4.2")
    implementation("androidx.camera:camera-view:1.4.2")
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
    implementation("io.coil-kt:coil-compose:2.7.0")
    implementation("dev.chrisbanes.haze:haze:1.6.10")
    testImplementation("junit:junit:4.13.2")
}
