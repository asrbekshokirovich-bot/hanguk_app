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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
