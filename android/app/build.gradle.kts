<<<<<<< HEAD
import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
keyProperties.load(FileInputStream(keyPropertiesFile))

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
=======
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> bf8aa91b4b1bfb71a1e9b475889f50976e4cae66
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.prodix.proconnect"
    compileSdk = flutter.compileSdkVersion

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
        // lint ഇവിടെ വരരുത്!
    }

    // ✅ lint ഇവിടെ വരണം — android {} block-ൽ directly
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

=======

    namespace = "com.prodix.proconnect"
    compileSdk = flutter.compileSdkVersion

>>>>>>> bf8aa91b4b1bfb71a1e9b475889f50976e4cae66
    defaultConfig {
        applicationId = "com.prodix.proconnect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

<<<<<<< HEAD
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

=======
>>>>>>> bf8aa91b4b1bfb71a1e9b475889f50976e4cae66
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

<<<<<<< HEAD
flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}



=======

flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
>>>>>>> bf8aa91b4b1bfb71a1e9b475889f50976e4cae66
