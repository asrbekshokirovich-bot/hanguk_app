import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config is loaded from android/key.properties (gitignored).
// See docs/RELEASE.md for keystore generation and CI restoration.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeys = keystorePropertiesFile.exists()
if (hasReleaseKeys) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.hanguk.studentapp.hanguk_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.hanguk.studentapp.hanguk_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // Pinned: Play Store 2026 hard requirement
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Always declare "release"; only configure it if key.properties is present.
        // Without key.properties, this config exists but has no key, so the
        // release buildType selection logic below falls back to debug-signing
        // and prints a loud warning.
        create("release") {
            if (hasReleaseKeys) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // Distribution channels.
    //
    // The app ships through two channels with conflicting update mechanisms:
    //   - "direct": self-distributed APK that updates itself by downloading
    //     and installing a new APK (install_plugin). Needs the
    //     REQUEST_INSTALL_PACKAGES permission, which lives ONLY in
    //     src/direct/AndroidManifest.xml.
    //   - "store":  Google Play. Play prohibits sideloading APKs, so this
    //     flavor must NOT carry REQUEST_INSTALL_PACKAGES; updates go through
    //     Play in-app updates (in_app_update). Build with:
    //       flutter build appbundle --flavor store --dart-define=STORE_BUILD=true
    //
    // Both flavors keep the same applicationId so Play sees one package.
    flavorDimensions += "distribution"
    productFlavors {
        create("direct") {
            dimension = "distribution"
        }
        create("store") {
            dimension = "distribution"
        }
    }

    buildTypes {
        release {
            // Use the real release signing config when keys are present;
            // otherwise fall back to debug signing (so `flutter run --release`
            // still works locally) but warn loudly so we never accidentally
            // ship a debug-signed APK.
            signingConfig = if (hasReleaseKeys) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "[hanguk] WARNING: android/key.properties not found. " +
                    "Falling back to DEBUG signing for the release build. " +
                    "Production releases MUST be signed with the real upload key. " +
                    "See docs/RELEASE.md."
                )
                signingConfigs.getByName("debug")
            }
            // R8 obfuscation + minification for release. Disable temporarily
            // if a class is being mangled — but try to fix it with proguard
            // rules first rather than turning these off in production.
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
