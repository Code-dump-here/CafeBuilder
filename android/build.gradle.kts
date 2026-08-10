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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
