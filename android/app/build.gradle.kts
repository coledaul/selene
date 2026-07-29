import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.moontechlab.selene"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14033849"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 保留原应用 ID，确保社区维护版本可以覆盖升级已有安装。
        applicationId = "org.moontechlab.selene"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // FFmpegKit 预编译包要求 Android API 24 及以上。
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val ciKeystorePath = System.getenv("SELENE_ANDROID_KEYSTORE_PATH")
    val ciStorePassword = System.getenv("SELENE_ANDROID_STORE_PASSWORD")
    val ciKeyAlias = System.getenv("SELENE_ANDROID_KEY_ALIAS")
    val ciKeyPassword = System.getenv("SELENE_ANDROID_KEY_PASSWORD")
    val hasCiSigningConfig = listOf(
        ciKeystorePath,
        ciStorePassword,
        ciKeyAlias,
        ciKeyPassword,
    ).all { !it.isNullOrBlank() }
    val hasLocalSigningConfig = keystorePropertiesFile.exists()
    val hasSigningConfig = hasCiSigningConfig || hasLocalSigningConfig

    signingConfigs {
        if (hasCiSigningConfig) {
            create("release") {
                storeFile = file(ciKeystorePath!!)
                storePassword = ciStorePassword
                keyAlias = ciKeyAlias
                keyPassword = ciKeyPassword
            }
        } else if (hasLocalSigningConfig) {
            create("release") {
                val properties = Properties()
                properties.load(FileInputStream(keystorePropertiesFile))
                
                storeFile = file(properties.getProperty("storeFile")!!)
                storePassword = properties.getProperty("storePassword")
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
            }
        }
    }

    gradle.taskGraph.whenReady {
        val runsReleaseTask = allTasks.any {
            it.name.contains("release", ignoreCase = true)
        }
        if (System.getenv("CI") == "true" && runsReleaseTask && !hasSigningConfig) {
            throw GradleException(
                "CI release builds require explicit Selene Android signing configuration"
            )
        }
    }

    buildTypes {
        release {
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for local development
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Enable R8 code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            // Keep debug builds fast
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
