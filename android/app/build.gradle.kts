plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "se.movera.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "se.movera.driver"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] =
            System.getenv("GOOGLE_MAPS_API_KEY") ?: ""
    }

    signingConfigs {
        create("release") {
            val storePath = System.getenv("MOVERA_UPLOAD_STORE_FILE")
            if (!storePath.isNullOrBlank()) {
                storeFile = file(storePath)
                storePassword = System.getenv("MOVERA_UPLOAD_STORE_PASSWORD") ?: ""
                keyAlias = System.getenv("MOVERA_UPLOAD_KEY_ALIAS") ?: ""
                keyPassword = System.getenv("MOVERA_UPLOAD_KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            val releaseStore = signingConfigs.getByName("release").storeFile
            signingConfig = if (releaseStore != null) {
                signingConfigs.getByName("release")
            } else {
                // Local/CI unsigned preview only. Production must set
                // MOVERA_UPLOAD_STORE_FILE and related env vars.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
