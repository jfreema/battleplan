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
    // Flutter checks these before every Android build and stops below its
    // floor. Flutter 3.50.0 needs the Android Gradle Plugin at 9.1.1 or later
    // and Kotlin at 2.4.10 or later (it applies Kotlin to the app itself,
    // since android.builtInKotlin is false). Raise them with FLUTTER_VERSION.
    id("com.android.application") version "9.1.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
}

include(":app")
