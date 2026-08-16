allprojects {
    repositories {
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
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for a file_picker 11.x packaging bug: its own android/build.gradle
// applies `com.android.library` but forgets `org.jetbrains.kotlin.android`, so
// its Kotlin `FilePickerPlugin` class is never compiled and the release build
// fails with "cannot find symbol FilePickerPlugin" in GeneratedPluginRegistrant.
// Apply the Kotlin Android plugin to that module ourselves until it's fixed
// upstream. See https://github.com/miguelpruivo/flutter_file_picker/issues/1973
subprojects {
    if (project.name == "file_picker") {
        project.pluginManager.apply("org.jetbrains.kotlin.android")
    }
}

// Plugin modules (file_picker, firebase_*) never pin their own Kotlin
// jvmTarget, so it follows whatever JDK Gradle happens to run on, while AGP
// compiles their Java at 17 either way. On the JDK 21 that Android Studio
// bundles that means Kotlin 21 against Java 17, and the build stops with
// "Inconsistent JVM-target compatibility detected". CI never sees it because
// the workflow pins temurin 17 and both sides agree by luck.
//
// Pin every module to 17, matching the `:app` module's own kotlin block, so
// the build no longer depends on which JDK the developer happens to have.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
