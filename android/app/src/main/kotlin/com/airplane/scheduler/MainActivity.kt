package com.airplane.scheduler

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import com.topjohnwu.superuser.Shell

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.airplane.scheduler/airplane_mode"
    private val ROOT_CHANNEL = "com.airplane.scheduler/root"

    private lateinit var permissionManager: PermissionManager
    private lateinit var airplaneModeManager: AirplaneModeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize libsu
        Shell.enableVerboseLogging = BuildConfig.DEBUG
        Shell.setDefaultBuilder(
            Shell.Builder.create()
                .setFlags(Shell.FLAG_REDIRECT_STDERR)
        )

        checkAndRequestRoot()
    }

    private fun checkAndRequestRoot() {
        Thread {
            try {
                val shell = Shell.getShell()
                if (shell.isRoot) {
                    Log.i("RootCheck", "Root granted")
                } else {
                    Log.w("RootCheck", "Root not granted")
                }
            } catch (e: Exception) {
                Log.e("RootCheck", "Root request failed", e)
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        permissionManager = PermissionManager(this)
        airplaneModeManager = AirplaneModeManager(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "hasExactAlarmPermission" ->
                    result.success(permissionManager.hasExactAlarmPermission())

                "requestExactAlarmPermission" -> {
                    permissionManager.requestExactAlarmPermission()
                    result.success(null)
                }

                "hasBatteryOptimizationExemption" ->
                    result.success(permissionManager.hasBatteryOptimizationExemption())

                "requestBatteryOptimizationExemption" -> {
                    permissionManager.requestBatteryOptimizationExemption()
                    result.success(null)
                }

                "hasWriteSecureSettingsPermission" ->
                    result.success(permissionManager.hasWriteSecureSettingsPermission())

                "openWriteSecureSettingsInstructions" -> {
                    permissionManager.openWriteSecureSettingsInstructions()
                    result.success(null)
                }

                "toggleAirplaneMode" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val success = airplaneModeManager.toggleAirplaneMode(enable)
                    result.success(success)
                }

                "isAirplaneModeOn" ->
                    result.success(airplaneModeManager.isAirplaneModeOn())

                "openAirplaneModeSettings" -> {
                    airplaneModeManager.openAirplaneModeSettings()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ROOT_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "forceRootRequest" -> {
                    checkAndRequestRoot()
                    result.success(true)
                }

                "hasRootAccess" ->
                    result.success(Shell.isAppGrantedRoot() == true)

                else -> result.notImplemented()
            }
        }
    }
}
