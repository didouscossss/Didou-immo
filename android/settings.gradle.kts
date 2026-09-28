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
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Lit android/app/google-services.json et génère les ressources natives
    // (default_web_client_id, google_app_id...) dont dépendent Firebase Auth
    // et le SDK natif Google Sign-In sur Android. Sans lui, google-services.json
    // reste un fichier inerte : les correctifs qui en dépendent (empreinte SHA-1
    // enregistrée côté Firebase, etc.) n'ont aucun effet sur le build.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
