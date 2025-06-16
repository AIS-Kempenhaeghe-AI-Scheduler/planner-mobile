pluginManagement {
    // Safer property loading with fallback
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        if (flutterSdkPath == null) {
            System.getenv("FLUTTER_ROOT") ?: throw GradleException("flutter.sdk not set in local.properties and FLUTTER_ROOT env var is not set")
        } else {
            flutterSdkPath
        }
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")

// Force Flutter to recognize v2 embedding
gradle.beforeProject {
    project.extensions.extraProperties["flutter.embedding.version"] = "2"
}
