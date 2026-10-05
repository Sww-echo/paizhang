import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) propertiesFile.inputStream().use { load(it) }
}
fun releaseValue(property: String, environment: String): String? =
    providers.gradleProperty("paizhang.$property").orNull
        ?: providers.environmentVariable(environment).orNull
        ?: signingProperties.getProperty(property)

val verificationRelease = providers.environmentVariable("PAIZHANG_VERIFY_RELEASE")
    .orElse(providers.gradleProperty("paizhang.verifyRelease")).orNull == "true"
val productionId = releaseValue("applicationId", "PAIZHANG_APPLICATION_ID")
val releaseStore = releaseValue("storeFile", "PAIZHANG_KEYSTORE_PATH")
val releaseStorePassword = releaseValue("storePassword", "PAIZHANG_KEYSTORE_PASSWORD")
val releaseAlias = releaseValue("keyAlias", "PAIZHANG_KEY_ALIAS")
val releaseKeyPassword = releaseValue("keyPassword", "PAIZHANG_KEY_PASSWORD")
val hasReleaseSigning = !verificationRelease &&
    listOf(releaseStore, releaseStorePassword, releaseAlias, releaseKeyPassword)
        .all { !it.isNullOrBlank() } && rootProject.file(releaseStore!!).isFile

android {
    namespace = "com.example.paizhang"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.paizhang"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseStore!!)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
    }
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.applicationId.set(if (verificationRelease) {
            "com.example.paizhang.verification"
        } else {
            productionId ?: "com.example.paizhang"
        })
    }
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { it.project.path == ":app" && it.name.contains("Release") }
    if (releaseRequested && !verificationRelease) {
        check(!productionId.isNullOrBlank() &&
            productionId.matches(Regex("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+")) &&
            !productionId.startsWith("com.example.")) {
            "Set a real PAIZHANG_APPLICATION_ID for production, or explicitly use PAIZHANG_VERIFY_RELEASE=true for unsigned verification."
        }
        check(hasReleaseSigning) {
            "Production release requires a valid keystore and signing values; debug signing is never used as a fallback. See android/key.properties.example."
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
