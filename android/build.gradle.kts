allprojects {
    repositories {
        google()
        mavenCentral()
        // Audit K3 (2026-05-11): Removed Kakao Maven repository
        // (https://devrepo.kakao.com/nexus/repository/kakaomap-releases/).
        // It was left over from an abandoned `kakao_maps_flutter` SDK
        // attempt. No Gradle dependency in this project pulls from it.
        // See docs/audits/kakaotalk_audit_2026-05-11.md §3 K3.
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
// honoring the `package` attribute in AndroidManifest.xml. A handful of
// pub.dev plugins we depend on still ship with pre-AGP-7.3 build files
// (e.g. `install_plugin` 2.1.0) and fail to configure with:
//
//   > Namespace not specified. Specify a namespace in the module's
//     build file: .../install_plugin-2.1.0/android/build.gradle.
//
// Editing the pub cache is not durable — `flutter pub get` rewrites it on
// every checkout — so we patch the offending subproject from this root
// build script instead. For every subproject that exposes an `android`
// extension without a namespace, we read the legacy `package` attribute
// out of its AndroidManifest.xml and feed it back through the DSL setter.
//
// Reflection is used because AGP types are not on the root buildscript
// classpath (Flutter applies them in :app via the Flutter Gradle plugin).
//
// Scope:
//   - Only touches subprojects whose `android.namespace` is null/blank.
//   - Skips :app, which already declares a namespace explicitly.
//   - Falls back to `project.group` only if the manifest has no package.
//
// Safety:
//   - Namespace must match what R class lookups expect, which historically
//     equalled the manifest `package`. Reading it back from the same
//     manifest preserves that identity.
//   - If neither source yields a value, we leave the project alone so the
//     original (informative) error is still surfaced rather than masked.
// ---------------------------------------------------------------------------
subprojects {
    afterEvaluate {
        if (project.path == ":app") return@afterEvaluate

        val androidExt = extensions.findByName("android") ?: return@afterEvaluate

        val currentNamespace = runCatching {
            androidExt.javaClass.getMethod("getNamespace").invoke(androidExt) as? String
        }.getOrNull()

        if (!currentNamespace.isNullOrBlank()) return@afterEvaluate

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
            ?: return@afterEvaluate

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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
