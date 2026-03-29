# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class hive.** { *; }
-keep class com.example.site_surveyor_compass.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Sensors Plus
-keep class com.baseflow.sensor.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Preserve line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
