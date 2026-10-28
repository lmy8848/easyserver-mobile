# Flutter release 构建默认开启 R8。ML Kit 通过反射（ComponentDiscovery）实例化
# BarcodeRegistrar，不打 keep 规则时 R8 会剥掉它的无参构造，运行时报
# NoSuchMethodException: BarcodeRegistrar.<init>[]，导致 mobile_scanner 插件注册失败、
# 扫码页黑屏只剩错误图标。
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**
