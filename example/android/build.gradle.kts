allprojects {
    repositories {
        google()
        mavenCentral()
        // Zettle SDK repository - requires GitHub authentication
        maven {
            url = uri("https://maven.pkg.github.com/iZettle/sdk-android")
            credentials {
                username = project.findProperty("github.username") as String? ?: System.getenv("GITHUB_USERNAME")
                password = project.findProperty("github.token") as String? ?: System.getenv("GITHUB_TOKEN")
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
