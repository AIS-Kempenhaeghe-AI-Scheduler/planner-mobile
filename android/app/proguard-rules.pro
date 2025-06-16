# Flutter Proguard Rules
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Dart VM
-keep class io.flutter.plugin.editing.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver