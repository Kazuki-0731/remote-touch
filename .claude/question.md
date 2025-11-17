まだ、BLE接続ができない。
こちら解消したい。
以下、macOSログとAndroidログです。

macOSログ
```
 >  flutter run -d macos                    
Launching lib/main.dart on macOS in debug mode...
Building macOS application...                                           
✓ Built build/macos/Build/Products/Debug/remote_touch.app
2025-11-18 01:38:50.773 remote_touch[78853:21574009] MainFlutterWindow: awakeFromNib called, initializing ApplicationController
2025-11-18 01:38:50.810 remote_touch[78853:21574009] ApplicationController: setupMenuBar() called
2025-11-18 01:38:50.815 remote_touch[78853:21574009] ApplicationController: statusItem created: true
2025-11-18 01:38:50.816 remote_touch[78853:21574009] ApplicationController: statusItem.button exists
2025-11-18 01:38:50.817 remote_touch[78853:21574009] ApplicationController: Set system symbol image
2025-11-18 01:38:50.828 remote_touch[78853:21574009] ApplicationController: Starting RemoteTouch
2025-11-18 01:38:50.828 remote_touch[78853:21574009] BLECentralManager: Cannot start scanning - Bluetooth not powered on
2025-11-18 01:38:50.829 remote_touch[78853:21574009] MainFlutterWindow: ApplicationController initialized and started
2025-11-18 01:38:50.842 remote_touch[78853:21574009] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                    33ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on macOS is available at: http://127.0.0.1:61995/BjGLvEpI__E=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:61995/BjGLvEpI__E=/devtools/?uri=ws://127.0.0.1:61995/BjGLvEpI__E=/ws
2025-11-18 01:38:51.539 remote_touch[78853:21574009] BLECentralManager: State changed to 5
2025-11-18 01:38:51.539 remote_touch[78853:21574009] BLECentralManager: Bluetooth powered on - ready to scan
2025-11-18 01:38:51.540 remote_touch[78853:21574009] BLECentralManager: Started scanning
```

Androidログ
```
>  flutter run -d 46111FDAQ0037T
Launching lib/main.dart on Pixel 9 in debug mode...
Running Gradle task 'assembleDebug'...                              4.9s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...           4.1s
D/FlutterJNI(22189): Beginning load of flutter...
D/FlutterJNI(22189): flutter (null) was loaded normally!
I/flutter (22189): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
Syncing files to device Pixel 9...                                  40ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on Pixel 9 is available at: http://127.0.0.1:62070/N4sB-jVW0fI=/
The Flutter DevTools debugger and profiler on Pixel 9 is available at: http://127.0.0.1:62070/N4sB-jVW0fI=/devtools/?uri=ws://127.0.0.1:62070/N4sB-jVW0fI=/ws
I/Choreographer(22189): Skipped 55 frames!  The application may be doing too much work on its main thread.
D/WindowOnBackDispatcher(22189): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@d4f367f
I/WindowExtensionsImpl(22189): Initializing Window Extensions, vendor API level=9, activity embedding enabled=true
I/le.remote_touch(22189): Compiler allocated 4970KB to compile void android.view.ViewRootImpl.performTraversals()
D/BluetoothGattServer(22189): registerCallback()
D/BluetoothGattServer(22189): registerCallback() - UUID=51f64ae3-83eb-495f-9bdc-0778b4b08497
D/BluetoothGattServer(22189): onServerRegistered(0)
D/BluetoothGattServer(22189): addService() - service: 12345678-1234-1234-1234-123456789abc
D/BLEPeripheralPlugin(22189): GATT Server setup complete
D/AdvertiseSettings(22189): setTxPowerLevel: 3
D/BluetoothAdapter(22189): isLeEnabled(): ON
E/BLEPeripheralPlugin(22189): Error starting advertising
E/BLEPeripheralPlugin(22189): java.lang.SecurityException: Need android.permission.BLUETOOTH_ADVERTISE permission for android.content.AttributionSource@2c0af064: BluetoothAdapterServiceBinder
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.createExceptionOrNull(Parcel.java:3355)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.createException(Parcel.java:3339)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.readException(Parcel.java:3322)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.readException(Parcel.java:3264)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.IBluetooth$Stub$Proxy.getNameLengthForAdvertise(IBluetooth.java:2425)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.BluetoothAdapter.getNameLengthForAdvertise(BluetoothAdapter.java:1702)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.totalBytes(BluetoothLeAdvertiser.java:724)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.startAdvertising(BluetoothLeAdvertiser.java:154)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.startAdvertising(BluetoothLeAdvertiser.java:116)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.startBleAdvertising(BLEPeripheralPlugin.kt:156)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.startAdvertising(BLEPeripheralPlugin.kt:96)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.onMethodCall(BLEPeripheralPlugin.kt:56)
E/BLEPeripheralPlugin(22189):   at io.flutter.plugin.common.MethodChannel$IncomingMethodCallHandler.onMessage(MethodChannel.java:267)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:292)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:319)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run(D8$$SyntheticClass:0)
E/BLEPeripheralPlugin(22189):   at android.os.Handler.handleCallback(Handler.java:1041)
E/BLEPeripheralPlugin(22189):   at android.os.Handler.dispatchMessage(Handler.java:103)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.dispatchMessage(Looper.java:315)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.loopOnce(Looper.java:251)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.loop(Looper.java:349)
E/BLEPeripheralPlugin(22189):   at android.app.ActivityThread.main(ActivityThread.java:9041)
E/BLEPeripheralPlugin(22189):   at java.lang.reflect.Method.invoke(Native Method)
E/BLEPeripheralPlugin(22189):   at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:593)
E/BLEPeripheralPlugin(22189):   at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:929)
D/BluetoothGattServer(22189): onServiceAdded() - handle=165 uuid=12345678-1234-1234-1234-123456789abc status=0
D/WindowLayoutComponentImpl(22189): Register WindowLayoutInfoListener on Context=com.example.remote_touch.MainActivity@ed7e4b4, of which baseContext=android.app.ContextImpl@8f97c57
D/ImeBackDispatcher(22189): switch root view (mImeCallbacks.size=0)
D/InsetsController(22189): hide(ime())
I/ImeTracker(22189): com.example.remote_touch:4c53f680: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/BluetoothGattServer(22189): registerCallback()
D/BluetoothGattServer(22189): registerCallback() - UUID=f5536562-fa8a-4c3f-bee8-96d1676a7ba4
D/BluetoothGattServer(22189): onServerRegistered(0)
D/BluetoothGattServer(22189): addService() - service: 12345678-1234-1234-1234-123456789abc
D/BLEPeripheralPlugin(22189): GATT Server setup complete
D/AdvertiseSettings(22189): setTxPowerLevel: 3
D/BluetoothAdapter(22189): isLeEnabled(): ON
D/BluetoothGattServer(22189): onServiceAdded() - handle=172 uuid=12345678-1234-1234-1234-123456789abc status=0
E/BLEPeripheralPlugin(22189): Error starting advertising
E/BLEPeripheralPlugin(22189): java.lang.SecurityException: Need android.permission.BLUETOOTH_ADVERTISE permission for android.content.AttributionSource@2c0af064: BluetoothAdapterServiceBinder
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.createExceptionOrNull(Parcel.java:3355)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.createException(Parcel.java:3339)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.readException(Parcel.java:3322)
E/BLEPeripheralPlugin(22189):   at android.os.Parcel.readException(Parcel.java:3264)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.IBluetooth$Stub$Proxy.getNameLengthForAdvertise(IBluetooth.java:2425)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.BluetoothAdapter.getNameLengthForAdvertise(BluetoothAdapter.java:1702)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.totalBytes(BluetoothLeAdvertiser.java:724)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.startAdvertising(BluetoothLeAdvertiser.java:154)
E/BLEPeripheralPlugin(22189):   at android.bluetooth.le.BluetoothLeAdvertiser.startAdvertising(BluetoothLeAdvertiser.java:116)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.startBleAdvertising(BLEPeripheralPlugin.kt:156)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.startAdvertising(BLEPeripheralPlugin.kt:96)
E/BLEPeripheralPlugin(22189):   at com.example.remote_touch.BLEPeripheralPlugin.onMethodCall(BLEPeripheralPlugin.kt:56)
E/BLEPeripheralPlugin(22189):   at io.flutter.plugin.common.MethodChannel$IncomingMethodCallHandler.onMessage(MethodChannel.java:267)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:292)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:319)
E/BLEPeripheralPlugin(22189):   at io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run(D8$$SyntheticClass:0)
E/BLEPeripheralPlugin(22189):   at android.os.Handler.handleCallback(Handler.java:1041)
E/BLEPeripheralPlugin(22189):   at android.os.Handler.dispatchMessage(Handler.java:103)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.dispatchMessage(Looper.java:315)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.loopOnce(Looper.java:251)
E/BLEPeripheralPlugin(22189):   at android.os.Looper.loop(Looper.java:349)
E/BLEPeripheralPlugin(22189):   at android.app.ActivityThread.main(ActivityThread.java:9041)
E/BLEPeripheralPlugin(22189):   at java.lang.reflect.Method.invoke(Native Method)
E/BLEPeripheralPlugin(22189):   at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:593)
E/BLEPeripheralPlugin(22189):   at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:929)
D/ProfileInstaller(22189): Installing profile for com.example.remote_touch
```
