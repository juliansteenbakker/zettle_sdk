group = "dev.steenbakker.zettle_sdk"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
}

// AGP 9 supplies Kotlin support itself, so applying the Kotlin plugin here would
// conflict with it. Apps on older Flutter versions still build this plugin with
// AGP 8, where the Kotlin plugin has to be applied explicitly.
// https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()
if (agpMajor < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

// Resolves this project's own dependencies below; consumers on AGP 9's settings
// `dependencyResolutionManagement` still allow a subproject-level `repositories { }`
// unless they explicitly set `repositoriesMode = FAIL_ON_PROJECT_REPOS`.
repositories {
    google()
    mavenCentral()
    // Zettle SDK repository - requires GitHub authentication
    maven {
        url = uri("https://maven.pkg.github.com/iZettle/sdk-android")
        credentials {
            username = findProperty("github.username") as String? ?: System.getenv("GITHUB_USERNAME")
            password = findProperty("github.token") as String? ?: System.getenv("GITHUB_TOKEN")
        }
    }
}

android {
    namespace = "dev.steenbakker.zettle_sdk"

    compileSdk = 36

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()

            it.testLogging {
                events("passed", "skipped", "failed", "standardOut", "standardError")
                showStandardStreams = true
            }

            it.outputs.upToDateWhen { false }
        }
    }
}

// Replaces the removed `kotlinOptions` block. It is configured through
// `extensions` instead of a `kotlin { }` block because the Kotlin extension only
// exists once something has applied the Kotlin plugin, which happens at
// different points depending on the AGP and Flutter version in the host app.
fun setKotlinJvmTarget() {
    extensions.configure(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java) {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }
}

if (extensions.findByName("kotlin") != null) {
    setKotlinJvmTarget()
} else {
    // AGP 9 with built-in Kotlin disabled: the Flutter Gradle Plugin applies the
    // Kotlin plugin to this project later on.
    plugins.withId("org.jetbrains.kotlin.android") { setKotlinJvmTarget() }
}

dependencies {
    // Zettle SDK dependencies
    val zettleVersion = "2.52.1"
    implementation("com.zettle.sdk:core:$zettleVersion")
    implementation("com.zettle.sdk.feature.cardreader:ui:$zettleVersion")

    // QRC (QR Code) payment features
    implementation("com.zettle.sdk.feature.qrc:core:$zettleVersion")
    implementation("com.zettle.sdk.feature.qrc:paypal-ui:$zettleVersion")
    implementation("com.zettle.sdk.feature.qrc:venmo-ui:$zettleVersion")

    // Manual Card Entry feature
    implementation("com.zettle.sdk.feature.manualcardentry:ui:$zettleVersion")

    // Activity result API for handling payment flows
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.lifecycle:lifecycle-process:2.8.7")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
