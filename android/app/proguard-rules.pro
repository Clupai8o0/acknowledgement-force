# kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-keep,includedescriptorclasses class com.clupai.force.**$$serializer { *; }
-keepclassmembers class com.clupai.force.** { *** Companion; }
-keepclasseswithmembers class com.clupai.force.** { kotlinx.serialization.KSerializer serializer(...); }
