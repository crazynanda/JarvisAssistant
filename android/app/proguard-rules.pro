# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Porcupine wake word - keep native libraries
-keep class ai.picovoice.porcupine.** { *; }
-dontwarn ai.picovoice.porcupine.**

# Keep Speech-to-Text
-keep class com.google.android.gms.speech.** { *; }
-dontwarn com.google.android.gms.**

# Keep audio players
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Google Play Core - ignore missing classes (not needed for basic app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# General Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
