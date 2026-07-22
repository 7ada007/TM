# Baseline ProGuard/R8 rules for release (minified) builds.
#
# Most Flutter plugins ship their own consumer-rules.pro bundled in their
# AAR, which R8 picks up automatically, so this file is intentionally
# small. It only adds keep rules for things that are easy to silently
# break under minification (JSON/reflection-shaped code) and are cheap to
# keep regardless of size impact.

# Keep Play Core / deferred-components split-install classes that the
# Flutter engine references reflectively for Android App Bundle support,
# even though this app doesn't currently use dynamic feature modules.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# flutter_secure_storage uses AndroidX Security crypto classes reflectively
# in places; keep them to avoid runtime ClassNotFoundException after
# shrinking.
-keep class androidx.security.crypto.** { *; }

# video_player / ExoPlayer: keep annotated members that ExoPlayer resolves
# via reflection.
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
