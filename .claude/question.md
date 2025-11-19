# 質問・課題メモ

このファイルにCI/CDのエラーや開発中の疑問点を記載してください。

```
Run flutter build apk --release
  flutter build apk --release
  shell: /usr/bin/bash -e {0}
  env:
    FLUTTER_ROOT: /opt/hostedtoolcache/flutter/stable-3.24.0-x64
    PUB_CACHE: /home/runner/.pub-cache
    JAVA_HOME: /opt/hostedtoolcache/Java_Zulu_jdk/17.0.17-10/x64
    JAVA_HOME_17_X64: /opt/hostedtoolcache/Java_Zulu_jdk/17.0.17-10/x64


Running Gradle task 'assembleRelease'...                        
FAILURE: Build completed with 2 failures.

1: Task failed with an exception.
-----------
* Where:
Build file '/home/runner/.pub-cache/hosted/pub.dev/flutter_blue_plus_android-7.0.4/android/build.gradle' line: 7

* What went wrong:
A problem occurred evaluating project ':flutter_blue_plus_android'.
> Could not get unknown property 'flutter' for extension 'android' of type com.android.build.gradle.LibraryExtension.

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

2: Task failed with an exception.
-----------
* What went wrong:
A problem occurred configuring project ':flutter_blue_plus_android'.
> Failed to notify project evaluation listener.
   > Cannot invoke method substring() on null object
   > Android Gradle Plugin: project ':flutter_blue_plus_android' does not specify `compileSdk` in build.gradle (/home/runner/.pub-cache/hosted/pub.dev/flutter_blue_plus_android-7.0.4/android/build.gradle).

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

BUILD FAILED in 2m 33s
Running Gradle task 'assembleRelease'...                          154.5s
Gradle task assembleRelease failed with exit code 1
Error: Process completed with exit code 1.
```
