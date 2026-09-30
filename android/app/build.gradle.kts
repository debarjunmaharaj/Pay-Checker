plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Direct Gradle Version Control
val appVersionCode = 1
val appVersionName = "1.0.0"

android {
    namespace = "com.netfie.pay_checker.pay_checker"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.netfie.pay_checker.pay_checker"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        
        // Direct version assignment in Gradle
        versionCode = appVersionCode
        versionName = appVersionName
    }

    buildTypes {
        release {
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
