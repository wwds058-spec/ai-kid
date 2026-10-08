import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing (upload key) ─────────────────────────────────────────────
// Google Play App Signing holds the app signing key; we sign uploads with our
// upload key. Values come from android/key.properties (local machine, never
// committed) or, if absent, environment variables (CI secrets).
// See docs/release/SIGNING.md.
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    (keyProperties.getProperty(property) ?: System.getenv(env))?.takeIf { it.isNotBlank() }

val uploadStoreFile = signingValue("storeFile", "ANDROID_UPLOAD_STORE_FILE")
val uploadStorePassword = signingValue("storePassword", "ANDROID_UPLOAD_STORE_PASSWORD")
val uploadKeyAlias = signingValue("keyAlias", "ANDROID_UPLOAD_KEY_ALIAS")
val uploadKeyPassword = signingValue("keyPassword", "ANDROID_UPLOAD_KEY_PASSWORD")
val hasUploadKey = listOf(uploadStoreFile, uploadStorePassword, uploadKeyAlias, uploadKeyPassword)
    .all { it != null }

// Store builds pass -PrequireUploadKey=true (or REQUIRE_UPLOAD_KEY=true):
// they must fail rather than silently fall back to debug signing.
val requireUploadKey = (findProperty("requireUploadKey") ?: System.getenv("REQUIRE_UPLOAD_KEY"))
    ?.toString() == "true"
if (requireUploadKey && !hasUploadKey) {
    throw GradleException(
        "Release signing required but the upload key is not configured. " +
            "Provide android/key.properties or the ANDROID_UPLOAD_* environment variables " +
            "(docs/release/SIGNING.md)."
    )
}

android {
    namespace = "com.yasvarlabs.aiexplorer"
    // Pinned (not inherited from the Flutter default) so a toolchain change can't
    // silently move them. Google Play requires targetSdk >= 36 for new apps and
    // updates since 2026-08-31; test/release_signoff_test.dart enforces it.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once the first build is uploaded to Google Play.
        applicationId = "com.yasvarlabs.aiexplorer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Upload key when configured. Otherwise debug keys, so local
            // `flutter run --release` works — such builds can't be uploaded to
            // Play, and store builds refuse this path (requireUploadKey).
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
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
