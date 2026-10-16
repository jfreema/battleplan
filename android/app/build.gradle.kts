plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.getbattleplan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.getbattleplan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Android 8.0 (SPEC §4.1)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        resValues = true
    }

    // Dev and prod install side by side (ARCH §5.7).
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Battleplan Dev")
            manifestPlaceholders["appLinkHost"] = "battleplan-dev-ecce4.web.app"
            manifestPlaceholders["authLinkHost"] = "battleplan-dev-ecce4.firebaseapp.com"
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Battleplan")
            manifestPlaceholders["appLinkHost"] = "getbattleplan.app"
            manifestPlaceholders["authLinkHost"] = "getbattleplan.app"
        }
    }

    // The Google Play upload key (store checklist 1.11). Only the Android
    // build workflow has it, from the repository's secrets: it writes the
    // PKCS #12 keystore to a temporary file and names it here. Nothing
    // builds Android on a developer's Mac.
    val uploadKeystore = System.getenv("ANDROID_UPLOAD_KEYSTORE")
    signingConfigs {
        if (uploadKeystore != null) {
            create("upload") {
                storeFile = file(uploadKeystore)
                storeType = "pkcs12"
                storePassword = System.getenv("ANDROID_UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_UPLOAD_KEY_ALIAS")
                // A PKCS #12 keystore has one password for both.
                keyPassword = System.getenv("ANDROID_UPLOAD_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Without the upload key, the debug key, so a release build
            // still runs; the workflow refuses to make a prod build that way.
            signingConfig = signingConfigs.findByName("upload")
                ?: signingConfigs.getByName("debug")
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
