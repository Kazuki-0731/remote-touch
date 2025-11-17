package com.example.remote_touch

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register BLE Peripheral Plugin
        flutterEngine.plugins.add(BLEPeripheralPlugin())
    }
}
