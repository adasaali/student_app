plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // لازم يكون آخر واحد بالقائمة، وبعد ما تضيف الفيرجن بـ settings.gradle.kts (شوف تحت)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.student_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // ⚠️ لازم تبدلها لاسم حقيقي فريد (زي com.academyschool.student) قبل
        // ما تسجل التطبيق بـ Firebase — نفس القيمة هون لازم تطابق تماماً
        // اللي بتسجله بـ Firebase Console وإلا الـ FCM ما رح يشتغل.
        applicationId = "com.academyschool.student" // أو أي اسم اخترته        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Import the Firebase BoM — يتحكم بنسخ كل مكتبات Firebase مع بعض
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Firebase Authentication — سجّل دخول المستخدمين
    implementation("com.google.firebase:firebase-auth")

    // Cloud Firestore — قاعدة بيانات
    implementation("com.google.firebase:firebase-firestore")

    // Firebase Cloud Messaging — إشعارات push (ذكرتها بتعليقك عن FCM)
    implementation("com.google.firebase:firebase-messaging")

    // مطلوبة عشان مكتبة flutter_local_notifications تشتغل (core library desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // TODO: أضف أي مكتبات Firebase ثانية تحتاجها هنا
    // https://firebase.google.com/docs/android/setup#available-libraries
}

flutter {
    source = "../.."
}