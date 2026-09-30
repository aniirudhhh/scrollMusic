plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.scrollmusic.scroll_music"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required for NewPipeExtractor on minSdk < 26
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.scrollmusic.scroll_music"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ndk {
        //     // arm64 = modern Android devices, armeabi-v7a = older 32-bit devices
        //     abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        // }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }


}



flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring â€” required for NewPipeExtractor on API < 26
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // AndroidX Media3 / ExoPlayer â€” audio playback engine
    val media3Version = "1.11.0"
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-session:$media3Version")
    implementation("androidx.media3:media3-common:$media3Version")

    // NewPipeExtractor â€” extracts YouTube audio stream URLs natively (no Python)
    implementation("com.github.teamnewpipe:NewPipeExtractor:v0.26.4")

    // OkHttp â€” HTTP client for NewPipeExtractor's Downloader implementation
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Kotlin coroutines for async extraction / playback management
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}













