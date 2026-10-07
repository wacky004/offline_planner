plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.multiplatform)
}

android {
    namespace = "com.offlineplanner.app"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.offlineplanner.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}

dependencies {
    implementation(project(":shared"))
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.session)
    implementation(libs.health.connect.client)
}
