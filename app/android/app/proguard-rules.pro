# Google Play Services / ML Kit shrinking workaround.
#
# Confirmed root cause of a real-device bug (both detectors always
# rejected, on every photo): the google_mlkit_face_detection AAR's own
# bundled consumer ProGuard rules only protect ONE narrow internal class
# (a `-keepclassmembers` for subclasses of
# com.google.android.gms.internal.mlkit_vision_internal_vkp.zzbel). They
# don't cover com.google.android.gms.internal.mlkit_vision_common, which is
# exactly where a real device crashed: a NullPointerException inside
# InputImage's internal construction, deep in reflection-dependent GMS glue
# that R8 renamed/stripped without knowing it was needed.
#
# Reproduced directly: a debug build (no R8) worked fine on the same real
# device; the release (minified) build crashed on it. An emulator with an
# older bundled Google Play Services version never showed this at all,
# which is why it wasn't caught during earlier testing — this only bites
# against a current, real Play Services build.
#
# Keep ML Kit's own classes and the specific GMS-internal ML Kit packages
# fully intact rather than chasing individual missing rules one at a time.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_common.**

-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_internal_vkp.**

-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_common.**
