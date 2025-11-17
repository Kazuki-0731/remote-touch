macOSのマウスが操作されない。
以下Androidログです。

Androidログ
```
 >  flutter run -d 46111FDAQ0037T
Launching lib/main.dart on Pixel 9 in debug mode...
Running Gradle task 'assembleDebug'...                           1,563ms
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...           4.3s
D/FlutterJNI(28221): Beginning load of flutter...
D/FlutterJNI(28221): flutter (null) was loaded normally!
I/flutter (28221): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
Syncing files to device Pixel 9...                                  21ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on Pixel 9 is available at: http://127.0.0.1:50204/Mc7d39FSU3Y=/
The Flutter DevTools debugger and profiler on Pixel 9 is available at: http://127.0.0.1:50204/Mc7d39FSU3Y=/devtools/?uri=ws://127.0.0.1:50204/Mc7d39FSU3Y=/ws
I/Choreographer(28221): Skipped 59 frames!  The application may be doing too much work on its main thread.
D/WindowOnBackDispatcher(28221): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@d4f367f
I/WindowExtensionsImpl(28221): Initializing Window Extensions, vendor API level=9, activity embedding enabled=true
I/le.remote_touch(28221): Compiler allocated 4970KB to compile void android.view.ViewRootImpl.performTraversals()
D/BluetoothGattServer(28221): registerCallback()
D/BluetoothGattServer(28221): registerCallback() - UUID=9f8c5691-f0be-432e-95e3-a560f1e029fd
D/BluetoothGattServer(28221): onServerRegistered(0)
D/BluetoothGattServer(28221): addService() - service: 12345678-1234-1234-1234-123456789abc
D/BLEPeripheralPlugin(28221): GATT Server setup complete
D/AdvertiseSettings(28221): setTxPowerLevel: 3
D/BluetoothAdapter(28221): isLeEnabled(): ON
D/BluetoothLeAdvertiser(28221): TxPower == ADVERTISE_TX_POWER_HIGH
D/BluetoothAdapter(28221): isLeEnabled(): ON
D/BluetoothGattServer(28221): onServerConnectionState() - status=0 connected=true device=XX:XX:XX:XX:D7:B6
D/BLEPeripheralPlugin(28221): Connection state changed: Connected to F4:D4:88:5B:D7:B6
D/BLEPeripheralPlugin(28221): Started BLE advertising
D/BluetoothGattServer(28221): onServiceAdded() - handle=165 uuid=12345678-1234-1234-1234-123456789abc status=0
I/flutter (28221): BLEPeripheralManager: Connected to Ishino Mac book
D/WindowLayoutComponentImpl(28221): Register WindowLayoutInfoListener on Context=com.example.remote_touch.MainActivity@ed7e4b4, of which baseContext=android.app.ContextImpl@d33f562
D/BLEPeripheralPlugin(28221): BLE Advertising started successfully
I/flutter (28221): BLEPeripheralManager: Advertising state changed to true
D/ImeBackDispatcher(28221): switch root view (mImeCallbacks.size=0)
D/InsetsController(28221): hide(ime())
I/ImeTracker(28221): com.example.remote_touch:c82c8dda: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN

Performing hot reload...                                                
Reloaded 0 libraries in 239ms (compile: 7 ms, reload: 0 ms, reassemble: 111 ms).
D/ProfileInstaller(28221): Installing profile for com.example.remote_touch

Performing hot reload...                                                
Reloaded 0 libraries in 159ms (compile: 9 ms, reload: 0 ms, reassemble: 73 ms).
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.91443452380949,"dy":-12.952380952380963,"type":"mouseMove","timestamp":1763400392894}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.742931547619065,"dy":-7.6953125,"type":"mouseMove","timestamp":1763400392905}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.6856398809523796,"dy":-2.3999255952380736,"type":"mouseMove","timestamp":1763400392908}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.7998511904761756,"dy":-2.0572916666667425,"type":"mouseMove","timestamp":1763400392911}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.5334821428571388,"dy":-2.3236607142856656,"type":"mouseMove","timestamp":1763400392913}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.495163690476204,"dy":-2.3999255952380736,"type":"mouseMove","timestamp":1763400392917}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.418898809523796,"dy":-1.8288690476190368,"type":"mouseMove","timestamp":1763400392922}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.3050595238095468,"dy":-1.6380208333333712,"type":"mouseMove","timestamp":1763400392926}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.1904761904761756,"dy":-2.1331845238095184,"type":"mouseMove","timestamp":1763400392931}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.11421130952382441,"dy":-1.4858630952380736,"type":"mouseMove","timestamp":1763400392934}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.6380208333333712,"type":"mouseMove","timestamp":1763400392938}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.3809523809523796,"dy":-2.5141369047619264,"type":"mouseMove","timestamp":1763400392943}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.943080357142776,"type":"mouseMove","timestamp":1763400392947}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.0762648809523796,"dy":-1.5238095238095184,"type":"mouseMove","timestamp":1763400392951}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952382441,"dy":-1.7905505952381873,"type":"mouseMove","timestamp":1763400392955}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-1.8284970238095184,"type":"mouseMove","timestamp":1763400392960}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.190476190476204,"dy":-1.7142857142856656,"type":"mouseMove","timestamp":1763400392964}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11458333333331439,"dy":-1.5238095238095184,"type":"mouseMove","timestamp":1763400392968}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.0758928571428612,"dy":-1.6380208333333712,"type":"mouseMove","timestamp":1763400392973}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.2287946428571388,"dy":-1.6000744047619264,"type":"mouseMove","timestamp":1763400392977}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.07626488095240802,"dy":-1.5238095238095184,"type":"mouseMove","timestamp":1763400392981}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.1045386904761472,"type":"mouseMove","timestamp":1763400392985}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.6383928571428896,"type":"mouseMove","timestamp":1763400392989}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.4092261904761472,"type":"mouseMove","timestamp":1763400392994}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-1.2191220238095184,"type":"mouseMove","timestamp":1763400392999}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.9144345238095184,"type":"mouseMove","timestamp":1763400393003}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.11421130952379599,"dy":-1.2191220238095184,"type":"mouseMove","timestamp":1763400393007}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.1045386904762609,"type":"mouseMove","timestamp":1763400393011}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.11421130952379599,"dy":-0.6856398809522943,"type":"mouseMove","timestamp":1763400393015}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-0.8381696428572241,"type":"mouseMove","timestamp":1763400393018}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.07626488095240802,"dy":-0.6097470238095184,"type":"mouseMove","timestamp":1763400393022}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.11421130952379599,"dy":-0.685639880952408,"type":"mouseMove","timestamp":1763400393027}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.9140625,"type":"mouseMove","timestamp":1763400393031}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.190476190476204,"dy":-0.9144345238095184,"type":"mouseMove","timestamp":1763400393035}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.7239583333332575,"type":"mouseMove","timestamp":1763400393039}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.07626488095240802,"dy":-0.49516369047626085,"type":"mouseMove","timestamp":1763400393043}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-1.1045386904761472,"type":"mouseMove","timestamp":1763400393048}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-0.8002232142856656,"type":"mouseMove","timestamp":1763400393052}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0,"dy":-0.41889880952385283,"type":"mouseMove","timestamp":1763400393056}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.6097470238095184,"type":"mouseMove","timestamp":1763400393060}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.609375,"type":"mouseMove","timestamp":1763400393064}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.07626488095240802,"dy":-0.49516369047614717,"type":"mouseMove","timestamp":1763400393069}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.49516369047626085,"type":"mouseMove","timestamp":1763400393073}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.41927083333337123,"type":"mouseMove","timestamp":1763400393077}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.07626488095240802,"dy":-0.19047619047614717,"type":"mouseMove","timestamp":1763400393082}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11421130952379599,"dy":-0.3046875,"type":"mouseMove","timestamp":1763400393086}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.190476190476204,"dy":-0.41889880952385283,"type":"mouseMove","timestamp":1763400393090}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.11458333333331439,"dy":-0.19047619047614717,"type":"mouseMove","timestamp":1763400393094}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.190476190476204,"dy":-0.41927083333337123,"type":"mouseMove","timestamp":1763400393099}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.3046875,"dy":-0.41889880952373915,"type":"mouseMove","timestamp":1763400393103}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.3046875,"dy":-0.380952380952408,"type":"mouseMove","timestamp":1763400393108}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.609375,"dy":-0.49516369047614717,"type":"mouseMove","timestamp":1763400393112}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":0.9144345238095184,"dy":-1.0286458333333712,"type":"mouseMove","timestamp":1763400393116}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":2.438244047619037,"dy":-2.0189732142856656,"type":"mouseMove","timestamp":1763400393120}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.8284970238095184,"dy":-0.4192708333335986,"type":"mouseMove","timestamp":1763400394498}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.6000744047619264,"dy":-0.19047619047614717,"type":"mouseMove","timestamp":1763400394506}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.8191964285714164,"dy":-0.7235863095238528,"type":"mouseMove","timestamp":1763400394513}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.6380208333333428,"dy":-0.3046875,"type":"mouseMove","timestamp":1763400394519}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.057291666666657,"dy":-0.6097470238095184,"type":"mouseMove","timestamp":1763400394525}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.7901785714285836,"dy":-0.49516369047626085,"type":"mouseMove","timestamp":1763400394532}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.8288690476190368,"dy":-0.49516369047614717,"type":"mouseMove","timestamp":1763400394533}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.818824404761898,"dy":-0.8381696428571104,"type":"mouseMove","timestamp":1763400394537}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.247767857142861,"dy":-0.685639880952408,"type":"mouseMove","timestamp":1763400394542}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.3333333333333428,"dy":-0.49516369047614717,"type":"mouseMove","timestamp":1763400394548}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-3.504836309523796,"dy":-1.8288690476190368,"type":"mouseMove","timestamp":1763400394557}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.3333333333333428,"dy":-0.609375,"type":"mouseMove","timestamp":1763400394561}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.2950148809523796,"dy":-0.609375,"type":"mouseMove","timestamp":1763400394566}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.2191220238095184,"dy":-0.6097470238095184,"type":"mouseMove","timestamp":1763400394571}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-1.0286458333333428,"dy":-0.49516369047626085,"type":"mouseMove","timestamp":1763400394576}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-0.8761160714285552,"dy":-0.5334821428571104,"type":"mouseMove","timestamp":1763400394577}
D/BLEPeripheralPlugin(28221): Sending command: {"dx":-2.3619791666666856,"dy":-0.990327380952408,"type":"mouseMove","timestamp":1763400394585}
```
