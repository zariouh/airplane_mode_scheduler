package com.airplane.scheduler

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.topjohnwu.superuser.Shell

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.airplane.scheduler/airplane_mode"
    private val ROOT_CHANNEL = "com.airplane.scheduler/root"

    private lateinit var permissionManager: PermissionManager
    private lateinit var airplaneModeManager: AirplaneModeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        initializeRoot()
        forceRootRequest()   // 🔥 Force popup on launch
    }

    /**
     * Configure libsu
     */
    private fun initializeRoot() {
        Shell.enableVerboseLogging = false

        Shell.setDefaultBuilder(
            Shell.Builder.create()
                .setFlags(Shell.FLAG_REDIRECT_STDERR)
                .setTimeout(10)
        )
    }

    /**
     * This ACTUALLY forces Magisk popup
     * by executing a real root command.
     */
    private fun forceRootRequest() {
        Thread {
            try {
                val result = Shell.cmd("id").exec()

                val isRoot = result.isSuccess &&
                        result.out.any { it.contains("uid=0") }

                if (isRoot) {
                    Log.i("RootCheck", "Root granted")
                } else {
                    Log.w("RootCheck", "Root denied or not available")
                }

            } catch (e: Exception) {
                Log.e("RootCheck", "Root request failed", e)
            }
        }.start()
    }

    /**
     * Actively checks root (not passive)
     */
    private fun hasRoot(): Boolean {
        val result = Shell.cmd("id").exec()
        return result.isSuccess &&
                result.out.any { it.contains("uid=0") }
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
                    result.success(airplaneModeManager.toggleAirplaneMode(enable))
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
                    forceRootRequest()
                    result.success(true)
                }

                "hasRootAccess" ->
                    result.success(hasRoot())

                else -> result.notImplemented()
            }
        }
    }
}
