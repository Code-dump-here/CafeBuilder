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

    // Some plugins (e.g. file_picker) apply their own, older Kotlin Gradle
    // Plugin instead of using Flutter's built-in Kotlin support. Loading two
    // different KGP versions in the same build breaks Java/Kotlin interop
    // across modules ("cannot find symbol" for classes that do exist) —
    // force every module to resolve the same KGP version as the app.
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "org.jetbrains.kotlin.android" ||
                requested.id.id == "org.jetbrains.kotlin.jvm"
            ) {
                useVersion("2.3.20")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Google services Gradle plugin (reads google-services.json)
    id("com.google.gms.google-services") version "4.5.0" apply false
}

include(":app")
