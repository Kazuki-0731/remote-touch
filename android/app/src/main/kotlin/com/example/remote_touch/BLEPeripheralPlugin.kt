package com.example.remote_touch

import android.Manifest
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.util.*

class BLEPeripheralPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null

    private var isAdvertising = false
    private var pendingResult: Result? = null
    private var connectedDevice: BluetoothDevice? = null

    // Handler for posting to main thread
    private val mainHandler = Handler(Looper.getMainLooper())

    // BLE Service and Characteristic UUIDs (must match iOS/macOS)
    companion object {
        private const val TAG = "BLEPeripheralPlugin"
        private const val CHANNEL_NAME = "remote_touch/ble_peripheral"
        private const val PERMISSION_REQUEST_CODE = 12345

        private val SERVICE_UUID = UUID.fromString("12345678-1234-1234-1234-123456789ABC")
        private val COMMAND_CHARACTERISTIC_UUID = UUID.fromString("12345678-1234-1234-1234-123456789ABD")
        private val STATUS_CHARACTERISTIC_UUID = UUID.fromString("12345678-1234-1234-1234-123456789ABE")
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
        bluetoothLeAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser

        Log.d(TAG, "BLEPeripheralPlugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAdvertising()
        context = null
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startAdvertising" -> {
                startAdvertising(result)
            }
            "stopAdvertising" -> {
                stopAdvertising()
                result.success(true)
            }
            "sendCommand" -> {
                @Suppress("UNCHECKED_CAST")
                val commandMap = call.arguments as? Map<String, Any>
                sendCommand(commandMap, result)
            }
            "isAdvertising" -> {
                result.success(isAdvertising)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startAdvertising(result: Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            Log.e(TAG, "Bluetooth is not enabled")
            result.success(false)
            return
        }

        if (!bluetoothAdapter!!.isMultipleAdvertisementSupported) {
            Log.e(TAG, "BLE advertising not supported on this device")
            result.success(false)
            return
        }

        if (isAdvertising) {
            Log.d(TAG, "Already advertising")
            result.success(true)
            return
        }

        // Check and request permissions for Android 12+ (API 31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!hasRequiredPermissions()) {
                Log.d(TAG, "Requesting Bluetooth permissions...")
                pendingResult = result
                requestPermissions()
                return
            }
        }

        try {
            setupGattServer()
            startBleAdvertising(result)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting advertising", e)
            result.success(false)
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothAdvertisePermission = ContextCompat.checkSelfPermission(
                context!!,
                Manifest.permission.BLUETOOTH_ADVERTISE
            )
            val bluetoothConnectPermission = ContextCompat.checkSelfPermission(
                context!!,
                Manifest.permission.BLUETOOTH_CONNECT
            )
            return bluetoothAdvertisePermission == PackageManager.PERMISSION_GRANTED &&
                   bluetoothConnectPermission == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun requestPermissions() {
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot request permissions")
            pendingResult?.success(false)
            pendingResult = null
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
            ActivityCompat.requestPermissions(activity!!, permissions, PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }

            if (allGranted) {
                Log.d(TAG, "Bluetooth permissions granted")
                // Retry starting advertising
                try {
                    setupGattServer()
                    startBleAdvertising(pendingResult!!)
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting advertising after permission grant", e)
                    pendingResult?.success(false)
                }
            } else {
                Log.e(TAG, "Bluetooth permissions denied")
                pendingResult?.success(false)
            }

            pendingResult = null
            return true
        }
        return false
    }

    private fun setupGattServer() {
        gattServer = bluetoothManager?.openGattServer(context, gattServerCallback)

        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

        // Command Characteristic (Write + Notify)
        val commandCharacteristic = BluetoothGattCharacteristic(
            COMMAND_CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )

        // Status Characteristic (Read + Notify)
        val statusCharacteristic = BluetoothGattCharacteristic(
            STATUS_CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )

        // Add Client Configuration Descriptor for notifications
        val commandDescriptor = BluetoothGattDescriptor(
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"),
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        commandCharacteristic.addDescriptor(commandDescriptor)

        val statusDescriptor = BluetoothGattDescriptor(
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"),
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        statusCharacteristic.addDescriptor(statusDescriptor)

        service.addCharacteristic(commandCharacteristic)
        service.addCharacteristic(statusCharacteristic)

        gattServer?.addService(service)
        Log.d(TAG, "GATT Server setup complete")
    }

    private fun startBleAdvertising(result: Result) {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        bluetoothLeAdvertiser?.startAdvertising(settings, data, advertiseCallback)
        Log.d(TAG, "Started BLE advertising")
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            super.onStartSuccess(settingsInEffect)
            isAdvertising = true
            Log.d(TAG, "BLE Advertising started successfully")
            channel.invokeMethod("onAdvertisingStateChanged", mapOf("isAdvertising" to true))
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            isAdvertising = false
            Log.e(TAG, "BLE Advertising failed with error code: $errorCode")
            channel.invokeMethod("onAdvertisingStateChanged", mapOf("isAdvertising" to false))
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            super.onConnectionStateChange(device, status, newState)

            val isConnected = newState == BluetoothProfile.STATE_CONNECTED
            Log.d(TAG, "Connection state changed: ${if (isConnected) "Connected" else "Disconnected"} to ${device.address}")

            // Store connected device
            if (isConnected) {
                connectedDevice = device
            } else {
                connectedDevice = null
            }

            // Post to main thread to avoid UiThread error
            mainHandler.post {
                channel.invokeMethod("onConnectionStateChanged", mapOf(
                    "isConnected" to isConnected,
                    "deviceAddress" to device.address,
                    "deviceName" to (device.name ?: "Unknown")
                ))
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value)

            if (characteristic.uuid == COMMAND_CHARACTERISTIC_UUID) {
                value?.let {
                    val commandJson = String(it, Charsets.UTF_8)
                    Log.d(TAG, "Received command: $commandJson")

                    // Post to main thread
                    mainHandler.post {
                        channel.invokeMethod("onCommandReceived", mapOf("command" to commandJson))
                    }
                }

                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic)

            if (characteristic.uuid == STATUS_CHARACTERISTIC_UUID) {
                val statusJson = """{"status":"idle","battery":100}"""
                gattServer?.sendResponse(
                    device,
                    requestId,
                    BluetoothGatt.GATT_SUCCESS,
                    offset,
                    statusJson.toByteArray(Charsets.UTF_8)
                )
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value)

            if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
            }

            Log.d(TAG, "Descriptor write request: ${descriptor.uuid}")
        }
    }

    private fun stopAdvertising() {
        if (isAdvertising) {
            bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
            isAdvertising = false
            Log.d(TAG, "Stopped BLE advertising")
        }

        gattServer?.close()
        gattServer = null
    }

    private fun sendCommand(commandMap: Map<String, Any>?, result: Result) {
        if (commandMap == null) {
            result.error("INVALID_ARGUMENT", "Command map is null", null)
            return
        }

        if (connectedDevice == null) {
            result.error("NOT_CONNECTED", "No device connected", null)
            return
        }

        try {
            // Convert Map to JSON string
            val jsonObject = JSONObject(commandMap)
            val commandJson = jsonObject.toString()
            Log.d(TAG, "Sending command: $commandJson")

            val service = gattServer?.getService(SERVICE_UUID)
            val characteristic = service?.getCharacteristic(COMMAND_CHARACTERISTIC_UUID)

            if (characteristic != null) {
                characteristic.value = commandJson.toByteArray(Charsets.UTF_8)
                // Notify connected device (not null!)
                gattServer?.notifyCharacteristicChanged(connectedDevice!!, characteristic, false)
                result.success(true)
            } else {
                Log.e(TAG, "Command characteristic not found")
                result.success(false)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending command", e)
            result.error("SEND_ERROR", "Failed to send command: ${e.message}", null)
        }
    }
}
