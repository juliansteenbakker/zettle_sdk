pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.4.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

// Replaces the `allprojects { repositories { } }` block that used to live in
// build.gradle, which AGP 9 no longer allows.
//
// The Zettle SDK repository is NOT declared here: the Flutter Gradle Plugin
// itself adds its own project-level repository (for engine artifacts) to
// every project via `rootProject.allprojects { repositories.maven { ... } }`.
// That triggers Gradle's default PREFER_PROJECT repositoriesMode, which
// silently ignores these settings-declared repositories for any project's own
// resolution once the project has any repository of its own - so the private
// repo has to be declared as a project-level repository too (see
// app/build.gradle.kts), the same way FGP declares its own.
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

include(":app")

