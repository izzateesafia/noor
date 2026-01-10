allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for sign_in_with_apple package: Add namespace to packages that don't have it
// This task patches the package's build.gradle file before evaluation
tasks.register("fixSignInWithAppleNamespace") {
    doLast {
        val pubCachePath = System.getenv("PUB_CACHE") 
            ?: "${System.getProperty("user.home")}/.pub-cache"
        
        val hostedPath = file("$pubCachePath/hosted/pub.dev")
        if (hostedPath.exists()) {
            // Find sign_in_with_apple package directories
            val signInWithAppleDirs = hostedPath.listFiles()?.filter { 
                it.isDirectory && it.name.startsWith("sign_in_with_apple-")
            } ?: emptyList()
            
            signInWithAppleDirs.forEach { packageDir ->
                val buildGradleFile = file("${packageDir.absolutePath}/android/build.gradle")
                if (buildGradleFile.exists()) {
                    val content = buildGradleFile.readText()
                    // Check if namespace is already present
                    if (!content.contains("namespace")) {
                        // Add namespace after android { block
                        val namespace = "com.aboutyou.dart_packages.sign_in_with_apple"
                        val updatedContent = content.replace(
                            "android {",
                            "android {\n    namespace '$namespace'"
                        )
                        try {
                            buildGradleFile.writeText(updatedContent)
                            println("✓ Added namespace to ${packageDir.name}")
                        } catch (e: Exception) {
                            println("⚠ Could not write to ${packageDir.name}: ${e.message}")
                            println("  Please run: bash android/fix_sign_in_with_apple.sh")
                        }
                    } else {
                        println("✓ Namespace already present in ${packageDir.name}")
                    }
                }
            }
        }
    }
}

// Also try to run the shell script as a fallback
tasks.register("fixSignInWithAppleNamespaceScript", Exec::class) {
    val scriptFile = file("fix_sign_in_with_apple.sh")
    if (scriptFile.exists()) {
        commandLine("bash", scriptFile.absolutePath)
        isIgnoreExitValue = true
    }
}

// Run the fix task before any build task
tasks.named("preBuild").configure {
    dependsOn("fixSignInWithAppleNamespace")
    dependsOn("fixSignInWithAppleNamespaceScript")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
