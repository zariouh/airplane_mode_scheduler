package com.airplane.scheduler

import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.airplane.scheduler/airplane_mode"
    private lateinit var permissionManager: PermissionManager
    private lateinit var airplaneModeManager: AirplaneModeManager

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
