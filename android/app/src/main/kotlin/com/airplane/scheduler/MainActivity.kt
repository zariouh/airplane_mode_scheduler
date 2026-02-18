package com.airplane.scheduler

import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.airplane.scheduler/airplane_mode"
    private val ROOT_CHANNEL = "com.airplane.scheduler/root" // New channel for root control

    private lateinit var permissionManager: PermissionManager
    private lateinit var airplaneModeManager: AirplaneModeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestRoot() // Try on startup
    }

    private fun checkAndRequestRoot() {
        Thread {
            try {
                Log.d("RootCheck", "Attempting su -c whoami")
                val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "whoami"))
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val output = reader.readText().trim()
                val errorReader = BufferedReader(InputStreamReader(process.errorStream))
                val error = errorReader.readText()
                process.waitFor()
                val exitCode = process.exitValue()

                Log.d("RootCheck", "su exit code: $exitCode, output: '$output', error: '$error'")

                if (exitCode == 0 && output == "root") {
                    Log.i("RootCheck", "Root granted")
                } else {
                    Log.w("RootCheck", "Root not granted")
                }
            } catch (e: Exception) {
                Log.e("RootCheck", "su call exception - popup should appear", e)
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        permissionManager = PermissionManager(this)
        airplaneModeManager = AirplaneModeManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Permission checks
                "hasExactAlarmPermission" -> {
                    result.success(permissionManager.hasExactAlarmPermission())
                }
                "requestExactAlarmPermission" -> {
                    permissionManager.requestExactAlarmPermission()
                    result.success(null)
                }
                "hasBatteryOptimizationExemption" -> {
                    result.success(permissionManager.hasBatteryOptimizationExemption())
                }
                "requestBatteryOptimizationExemption" -> {
                    permissionManager.requestBatteryOptimizationExemption()
                    result.success(null)
                }
                "hasWriteSecureSettingsPermission" -> {
                    result.success(permissionManager.hasWriteSecureSettingsPermission())
                }
                "openWriteSecureSettingsInstructions" -> {
                    permissionManager.openWriteSecureSettingsInstructions()
                    result.success(null)
                }

                // Airplane mode operations
                "toggleAirplaneMode" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val success = airplaneModeManager.toggleAirplaneMode(enable)
                    result.success(success)
                }
                "isAirplaneModeOn" -> {
                    result.success(airplaneModeManager.isAirplaneModeOn())
                }
                "openAirplaneModeSettings" -> {
                    airplaneModeManager.openAirplaneModeSettings()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // New channel for forcing root request from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROOT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceRootRequest" -> {
                    checkAndRequestRoot()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
    }
}
