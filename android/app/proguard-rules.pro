# Flutter and plugin keep rules to avoid stripping required classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin metadata (used by reflection in some plugins)
-keep class kotlin.Metadata { *; }

# Avoid warnings for Java 8 desugaring
-dontwarn java.lang.invoke.*

# AndroidX lifecycle commonly used by plugins
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class androidx.lifecycle.** { *; }

# Keep generated registrant (older embedding)
-keep class **.GeneratedPluginRegistrant { *; }

