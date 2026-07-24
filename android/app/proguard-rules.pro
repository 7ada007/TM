# R8 rules for release (minified) builds.
#
# Two jobs here: keep the things that break silently under shrinking
# (reflection-shaped code), and make the surviving bytecode as unpleasant to
# read as R8 allows.
#
# Note on scope: the bulk of this app's logic is Dart compiled to native ARM
# code in libapp.so, which R8 never sees. Dart-level protection comes from
# `flutter build --obfuscate` (see tool/build_release.sh). These rules harden
# the Java/Kotlin shell around it.

# ---------------------------------------------------------------------------
# Obfuscation aggressiveness
# ---------------------------------------------------------------------------

# Flatten every surviving class into a single unnamed package. Destroys the
# original package hierarchy, which is most of what makes a decompiled tree
# navigable.
-repackageclasses ''
-allowaccessmodification

# Rename the source-file attribute to a single token so stack traces leak
# nothing. mapping.txt (kept out of the repo) de-obfuscates real crashes.
-renamesourcefileattribute SRC
-keepattributes SourceFile,LineNumberTable

# Strip logging from the release binary so leftover debug output cannot
# narrate internals to anyone watching logcat.
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
}

# ---------------------------------------------------------------------------
# Keep rules — these break at runtime if shrunk
# ---------------------------------------------------------------------------

# Flutter embedding: the engine instantiates these reflectively from the
# manifest and from generated plugin registrant code.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core / deferred components: referenced reflectively by the Flutter
# engine for App Bundle support even though no dynamic features are used.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# flutter_secure_storage reaches AndroidX Security crypto classes reflectively.
# This backs the JWT at rest, so a ClassNotFoundException here is a hard
# login failure.
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# video_player / ExoPlayer resolve members via reflection.
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Rive renders through JNI into its native library.
-keep class app.rive.runtime.** { *; }
-dontwarn app.rive.runtime.**

# Native methods must keep their names for JNI symbol lookup to resolve.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum valueOf/values are resolved reflectively by the platform.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable CREATOR fields are looked up by name.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
