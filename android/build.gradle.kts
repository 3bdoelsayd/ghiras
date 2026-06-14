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
                    kotlinOptions.jvmTarget = "17"
                }
            }

            if (android.namespace == null) {
                android.namespace = "com.ghiras.${project.name.replace("-", "_").replace(":", "_")}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
