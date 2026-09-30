pluginManagement {
    run {
        try {
            val env = System.getenv()
            val field = env.javaClass.getDeclaredField("m")
            field.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val map = field.get(env) as? MutableMap<String, String>
            map?.remove("ANDROID_PREFS_ROOT")
            map?.remove("ANDROID_SDK_HOME")
        } catch (_: Throwable) {}
        try {
            val pe = Class.forName("java.lang.ProcessEnvironment")
            val field = pe.getDeclaredField("theCaseInsensitiveEnvironment")
            field.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val map = field.get(null) as? MutableMap<String, String>
            map?.remove("ANDROID_PREFS_ROOT")
            map?.remove("ANDROID_SDK_HOME")
        } catch (_: Throwable) {}
    }

    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val path = properties.getProperty("flutter.sdk")
        if (path != null && file(path).exists()) {
            return@run path
        }
        val envPath = System.getenv("FLUTTER_ROOT") ?: System.getenv("FLUTTER_HOME")
        if (envPath != null && file(envPath).exists()) {
            return@run envPath
        }
        val fallback = "D:/flutter"
        if (file(fallback).exists()) {
            return@run fallback
        }
        "C:/flutter"
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
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.10.0"
}

include(":app")
