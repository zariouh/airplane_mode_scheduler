package com.airplane.scheduler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
        private const val CHANNEL = "com.airplane.scheduler/airplane_mode"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Alarm received!")

        val enableAirplaneMode = intent.getBooleanExtra("enable", false)
        val scheduleId = intent.getStringExtra("scheduleId") ?: ""
        val scheduleName = intent.getStringExtra("scheduleName") ?: "Schedule"

        Log.i(TAG, "Schedule: $scheduleName, Enable: $enableAirplaneMode")

        // Toggle airplane mode
        val airplaneModeManager = AirplaneModeManager(context)
        val success = airplaneModeManager.toggleAirplaneMode(enableAirplaneMode)

        if (success) {
            Log.i(TAG, "Airplane mode toggled successfully")
            
            // Show notification
            val notificationHelper = NotificationHelper(context)
            notificationHelper.showAirplaneModeNotification(enableAirplaneMode, scheduleName)
        } else {
            Log.w(TAG, "Failed to toggle airplane mode automatically")
            
            // Show notification asking user to toggle manually
            val notificationHelper = NotificationHelper(context)
            notificationHelper.showManualToggleNotification(enableAirplaneMode, scheduleName)
        }

        // Reschedule the alarm for the next occurrence
        // This is handled by AlarmManager with setRepeating or by rescheduling in the app
    }
}
