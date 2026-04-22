# Keep WireGuard plugin/service classes referenced by reflection.
-keep class com.wireguard.** { *; }
-keep class com.protocoder.wireguard_flutter_plus.** { *; }

# Keep Google Mobile Ads classes and mediation adapter metadata.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
