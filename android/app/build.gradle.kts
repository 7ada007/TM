plugins {
    id("com.android.application")
    // Flutter Gradle Plugin must be applied after the Android plugin.
    // Kotlin support is built-in — no separate kotlin-android plugin needed.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tareeqalmajd.studentapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Must match Kotlin's JVM target (21 is the default in Kotlin 2.x + AGP 9).
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.tareeqalmajd.studentapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Shrink + obfuscate the Android-side (Kotlin/Java plugin) code
            // and drop unused resources for smaller, faster-loading release
            // APKs. This does not affect the Dart AOT snapshot (Flutter/Dart
            // code is compiled and optimized separately) — only the native
            // Android plugin glue. See proguard-rules.pro for the handful
            // of keep rules needed for plugins that use reflection.
            // NOTE: this is a build-config change that should be verified
            // with a real `flutter build apk --release` + smoke test on a
            // device before shipping, same as everything else in this
            // change set — it was not (and could not be) built here.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
