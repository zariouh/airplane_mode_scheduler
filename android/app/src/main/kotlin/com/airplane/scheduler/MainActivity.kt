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
    private lateinit var alarmScheduler: AlarmScheduler

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initializeRoot()
        // Root request moved to onFlutterUiDisplayed — don't request here
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        // Flutter UI is fully visible and window is focused
        // Magisk popup will now appear reliably on first launch
        forceRootRequest()
    }

    private fun initializeRoot() {
        Shell.enableVerboseLogging = false
        Shell.setDefaultBuilder(
            Shell.Builder.create()
                .setFlags(Shell.FLAG_REDIRECT_STDERR)
                .setTimeout(10)
        )
    }

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

    private fun hasRoot(): Boolean {
        val result = Shell.cmd("id").exec()
        return result.isSuccess &&
                result.out.any { it.contains("uid=0") }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        permissionManager = PermissionManager(this)
        airplaneModeManager = AirplaneModeManager(this)
        alarmScheduler = AlarmScheduler(this)

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

                "scheduleAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: 0
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val enable = call.argument<Boolean>("enable") ?: false
                    val scheduleName = call.argument<String>("scheduleName") ?: ""
                    @Suppress("UNCHECKED_CAST")
                    val daysOfWeek = call.argument<List<Boolean>>("daysOfWeek") ?: emptyList()
                    alarmScheduler.scheduleAlarm(alarmId, hour, minute, daysOfWeek, enable, scheduleName)
                    result.success(true)
                }

                "cancelAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: 0
                    alarmScheduler.cancelAlarm(alarmId)
                    result.success(true)
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

                "hasRootAccess" -> {
                    Thread {
                        val hasRoot = hasRoot()
                        runOnUiThread { result.success(hasRoot) }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }
}
