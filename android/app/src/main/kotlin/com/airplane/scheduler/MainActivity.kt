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
    private lateinit var permissionManager: PermissionManager
    private lateinit var airplaneModeManager: AirplaneModeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestRoot()  // Triggers Magisk root popup on first launch
    }

    /**
     * Triggers Magisk superuser popup the first time by attempting a harmless root command.
     * Magisk will show "Allow [App] to use root?" – user grants once, remembered forever.
     */
    private fun checkAndRequestRoot() {
        Thread {  // Run off main thread to avoid blocking UI
            try {
                val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "whoami"))
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val output = reader.readText().trim()
                process.waitFor()

                val exitCode = process.exitValue()

                if (exitCode == 0 && output == "root") {
                    Log.i("RootCheck", "Root access granted and confirmed")
                    // Optional: You can send to Flutter via channel if you want UI feedback
                } else {
                    Log.w("RootCheck", "Root access denied or failed (exit $exitCode)")
                }
            } catch (e: Exception) {
                // First time this runs, Magisk popup appears here
                Log.i("RootCheck", "Root request triggered - Magisk popup should appear now")
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
               
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Notify Flutter that permissions might have changed
        // This is handled by the app lifecycle
    }
}
