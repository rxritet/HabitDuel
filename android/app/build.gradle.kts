import com.android.build.api.variant.ApplicationAndroidComponentsExtension

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.rxritet.habitduel"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.rxritet.habitduel"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Demo APKs are debug-signed. Use a release keystore before Play Store publishing.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

extensions.configure<ApplicationAndroidComponentsExtension>("androidComponents") {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            val versionName = variant.versionName.orNull ?: "0.0.0"
            val versionCode = variant.versionCode.orNull ?: 0
            output.outputFileName.set(
                "HabitDuel-v${versionName}+${versionCode}-${variant.buildType}.apk",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
