allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure flutter extension for all subprojects before evaluation
subprojects {
    project.ext.set("flutter.compileSdkVersion", 34)
    project.ext.set("flutter.minSdkVersion", 21)
    project.ext.set("flutter.targetSdkVersion", 34)
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
