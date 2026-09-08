plugins {
    // ...
    id("com.google.gms.google-services") version "4.5.0" apply false
}

allprojects {
    repositories {
        maven { url = uri(rootProject.projectDir.resolve("offline-repo")) }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🆕 file_picker (وأي بلجن تاني بيحدد compileSdk تبعه اعتماداً على القيمة
// الافتراضية من Flutter SDK المثبت عندك، مش من إعداد compileSdk اللي حطيناه
// بـ app/build.gradle.kts) — نسخة Flutter الحالية عندك لسا افتراضياً 34،
// فبيصير تعارض مع flutter_plugin_android_lifecycle اللي بيتطلب 36+.
// هاي الكتلة بتجبر *كل* المشاريع الفرعية (بما فيها المكتبات) تستخدم 36،
// بغض النظر شو حاطين بإعداداتهم الداخلية.
// ⚠️ لازم تكون *قبل* evaluationDependsOn(":app") تحت — هاي بتجبر تقييم
// المشروع الفرعي فوراً، وتسجيل afterEvaluate بعدها على مشروع مقيّم أصلاً
// بيرمي "Cannot run Project.afterEvaluate(Action) when the project is
// already evaluated." (بالضبط الخطأ يلي صار).
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}