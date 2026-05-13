allprojects {
    repositories {
        google()
        mavenCentral()
        // Audit K3 (2026-05-11): Removed Kakao Maven repository
        // (https://devrepo.kakao.com/nexus/repository/kakaomap-releases/).
        // It was left over from an abandoned `kakao_maps_flutter` SDK
        // attempt. No Gradle dependency in this project pulls from it.
        // See docs/audits/kakaotalk_audit_2026-05-11.md sec 3 K3.
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

// ---------------------------------------------------------------------------
// AGP-8 namespace shim for legacy plugins.
//
// AGP 8 made the `android.namespace` DSL property mandatory and stopped
// honoring the `package` attribute in AndroidManifest.xml. Some pub.dev
// plugins still ship with pre-AGP-7.3 build files (e.g. `install_plugin`
// 2.1.0) and fail with:
//   > Namespace not specified.
//
// We patch each offending subproject by reading the legacy `package` out
// of its AndroidManifest.xml and feeding it through the DSL setter via
// reflection (AGP types are not on the root buildscript classpath here).
//
// Dispatch is dynamic because the `evaluationDependsOn(":app")` block
// above forces eager evaluation of dependent subprojects. When we reach
// this hook, some plugins are already in the evaluated state and Gradle
// rejects a fresh `afterEvaluate` registration. So: if the subproject is
// already evaluated, apply the shim immediately; otherwise queue it.
// ---------------------------------------------------------------------------
subprojects {
    val applyNamespaceShim = Action<Project> {
        if (project.path == ":app") return@Action

        val androidExt = extensions.findByName("android") ?: return@Action

        val currentNamespace = runCatching {
            androidExt.javaClass.getMethod("getNamespace").invoke(androidExt) as? String
        }.getOrNull()

        if (!currentNamespace.isNullOrBlank()) return@Action

        val manifestPackage = runCatching {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (!manifestFile.exists()) return@runCatching null
            Regex("""package\s*=\s*["']([^"']+)["']""")
                .find(manifestFile.readText())
                ?.groupValues
                ?.get(1)
        }.getOrNull()

        val injected = manifestPackage
            ?: project.group.toString().takeIf { it.isNotBlank() }
            ?: return@Action

        runCatching {
            androidExt.javaClass
                .getMethod("setNamespace", String::class.java)
                .invoke(androidExt, injected)
            logger.lifecycle(
                "[hanguk] Injected namespace '$injected' for ${project.path} " +
                    "(plugin predates AGP 8 namespace requirement)."
            )
        }
    }
    if (state.executed) {
        applyNamespaceShim.execute(this)
    } else {
        afterEvaluate(applyNamespaceShim)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
