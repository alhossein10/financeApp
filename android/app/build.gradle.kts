plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.finance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.finance_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "version"
    
    productFlavors {
        create("superAdmin") {
            dimension = "version"
            applicationId = "com.app.finance.superadmin"
            // App name is defined in android/app/src/superAdmin/res/values/strings.xml
        }
        
        create("admin") {
            dimension = "version"
            applicationId = "com.app.finance.admin"
            // App name is defined in android/app/src/admin/res/values/strings.xml
        }
        
        create("user") {
            dimension = "version"
            applicationId = "com.app.finance.user"
            // App name is defined in android/app/src/user/res/values/strings.xml
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // DISABLED: Code shrinking and minification to avoid R8 errors
            // Split APKs still provide significant size reduction (~30-40 MB savings)
            // To re-enable minification later, set isMinifyEnabled = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
