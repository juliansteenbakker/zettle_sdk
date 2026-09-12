plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The Flutter Gradle Plugin adds its own project-level repository (for engine
// artifacts) to every project, which makes Gradle ignore the settings-level
// `dependencyResolutionManagement` repositories for this project's own
// resolution. So the Zettle SDK repository has to be declared here too,
// alongside FGP's, rather than only in settings.gradle.kts.
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/iZettle/sdk-android")
        credentials {
            username = providers.gradleProperty("github.username").orNull
                ?: System.getenv("GITHUB_USERNAME")
            password = providers.gradleProperty("github.token").orNull
                ?: System.getenv("GITHUB_TOKEN")
        }
    }
}

android {
    namespace = "dev.steenbakker.zettle_sdk_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.steenbakker.zettle_sdk_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
