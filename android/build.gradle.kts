import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as BaseExtension
            
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            
            if (project.plugins.hasPlugin("org.jetbrains.kotlin.android")) {
                project.tasks.withType<KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    }
                }
            }

            if (android.namespace == null) {
                android.namespace = "com.ghiras.${project.name.replace("-", "_").replace(":", "_")}"
            }

            // Force namespace for libraries and remove package from manifest
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val content = manifestFile.readText()
                if (content.contains("package=")) {
                    val namespace = Regex("""package="([^"]*)"""").find(content)?.groups?.get(1)?.value
                    if (namespace != null && android.namespace == null) {
                        android.namespace = namespace
                    }
                    val newContent = content.replace(Regex("""package="[^"]*""""), "")
                    manifestFile.writeText(newContent)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
