// Kept in sync with android/app/build.gradle.kts (flutter.compileSdkVersion /
// flutter.minSdkVersion), which is not readable from the root project.
val FLUTTER_COMPILE_SDK = 36
val FLUTTER_MIN_SDK = 24

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Bring plugin modules that still target an older SDK up to the app's
    // compileSdk/minSdk. Uses the stable `com.android.build.api.dsl` types;
    // the legacy `BaseExtension`/`compileSdkVersion()` APIs are deprecated in
    // AGP 9 and scheduled for removal.
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is com.android.build.api.dsl.LibraryExtension) {
            val compileSdk = androidExtension.compileSdk
            if (compileSdk == null || compileSdk < FLUTTER_COMPILE_SDK) {
                androidExtension.compileSdk = FLUTTER_COMPILE_SDK
            }
            val minSdk = androidExtension.defaultConfig.minSdk
            if (minSdk == null || minSdk < FLUTTER_MIN_SDK) {
                androidExtension.defaultConfig.minSdk = FLUTTER_MIN_SDK
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
