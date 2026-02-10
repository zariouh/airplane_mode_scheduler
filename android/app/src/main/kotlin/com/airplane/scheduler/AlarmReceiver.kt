package com.airplane.scheduler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver for handling alarm events
 * This receiver is triggered when scheduled alarms fire
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
        const val EXTRA_ENABLE = "enable"
        const val EXTRA_SCHEDULE_NAME = "schedule_name"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Alarm received")
        
        try {
            // Get the enable flag from intent
            val enable = intent.getBooleanExtra(EXTRA_ENABLE, false)
            val scheduleName = intent.getStringExtra(EXTRA_SCHEDULE_NAME) ?: "Unknown"
            
            Log.i(TAG, "Processing alarm: enable=$enable, schedule=$scheduleName")
            
            // Toggle airplane mode
            val airplaneModeManager = AirplaneModeManager(context)
            val success = airplaneModeManager.toggleAirplaneMode(enable)
            
            if (success) {
                Log.i(TAG, "Successfully toggled airplane mode: $enable")
                
                // Optionally send a broadcast to Flutter for UI update
                val broadcastIntent = Intent("com.airplane.scheduler.AIRPLANE_MODE_CHANGED").apply {
                    putExtra("enabled", enable)
                    putExtra("schedule_name", scheduleName)
                    putExtra("success", true)
                }
                context.sendBroadcast(broadcastIntent)
            } else {
                Log.w(TAG, "Failed to toggle airplane mode")
                
                // Send failure broadcast
                val broadcastIntent = Intent("com.airplane.scheduler.AIRPLANE_MODE_CHANGED").apply {
                    putExtra("enabled", enable)
                    putExtra("schedule_name", scheduleName)
                    putExtra("success", false)
                }
                context.sendBroadcast(broadcastIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing alarm", e)
        }
    }
}
