import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("development") {
            dimension = "flavor-type"
            applicationId = "com.example.tuhubread"
            resValue(type = "string", name = "app_name", value = "TuHuBread.Dev")
        }
        create("production") {
            dimension = "flavor-type"
            applicationId = "com.example.tuhubread.prod"
            resValue(type = "string", name = "app_name", value = "TuHuBread")
        }
    }

    buildFeatures.resValues = true
}