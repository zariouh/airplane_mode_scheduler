package com.airplane.scheduler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver for handling device boot events
 * This receiver launches the app in the background after boot to reschedule alarms
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "Boot completed - starting app to reschedule alarms")
            
            try {
                // ✅ IMPROVED: Launch the app in the background
                // This will trigger main.dart's _rescheduleAllEnabledSchedules()
                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                
                if (launchIntent != null) {
                    // Add flags to start the app in background without showing UI
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    // Remove FLAG_ACTIVITY_CLEAR_TOP to keep it in background
                    
                    context.startActivity(launchIntent)
                    Log.i(TAG, "App launched successfully for alarm rescheduling")
                } else {
                    Log.w(TAG, "Could not get launch intent for app")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error launching app on boot", e)
            }
        }
    }
}
