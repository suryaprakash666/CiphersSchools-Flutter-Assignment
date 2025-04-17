plugins {
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// IMPORTANT: Comment out all custom build directory configuration
// DO NOT use these for Flutter builds as they cause path confusion
// val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
// rootProject.layout.buildDirectory.value(newBuildDir)
// 
// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
