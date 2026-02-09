package com.airplane.scheduler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "Boot completed - rescheduling alarms")
            
            // Reschedule all enabled alarms
            // This requires access to the database, which we'll handle through Flutter
            // The Flutter app will reschedule alarms when it starts
            
            // For now, just log that boot completed
            // The actual rescheduling happens when the app launches
        }
    }
}
