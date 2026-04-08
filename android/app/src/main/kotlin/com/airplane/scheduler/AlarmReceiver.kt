package com.airplane.scheduler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
        const val EXTRA_ENABLE = "enable"
        const val EXTRA_SCHEDULE_NAME = "schedule_name"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_HOUR = "hour"
        const val EXTRA_MINUTE = "minute"
        const val EXTRA_DAYS_OF_WEEK = "days_of_week" // comma-separated "true,false,true,..."
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Alarm received")

        try {
            val enable = intent.getBooleanExtra(EXTRA_ENABLE, false)
            val scheduleName = intent.getStringExtra(EXTRA_SCHEDULE_NAME) ?: "Unknown"
            val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
            val hour = intent.getIntExtra(EXTRA_HOUR, -1)
            val minute = intent.getIntExtra(EXTRA_MINUTE, -1)
            val daysOfWeekStr = intent.getStringExtra(EXTRA_DAYS_OF_WEEK) ?: ""

            // Toggle airplane mode
            val success = AirplaneModeManager(context).toggleAirplaneMode(enable)

            if (success) {
                Log.i(TAG, "Successfully toggled airplane mode: enable=$enable")
            } else {
                Log.w(TAG, "Failed to toggle airplane mode")
            }

            // Reschedule for next occurrence if we have all the data
            if (alarmId != -1 && hour != -1 && minute != -1 && daysOfWeekStr.isNotEmpty()) {
                val daysOfWeek = daysOfWeekStr.split(",").map { it.trim() == "true" }
                val alarmScheduler = AlarmScheduler(context)
                alarmScheduler.scheduleAlarm(
                    alarmId = alarmId,
                    hour = hour,
                    minute = minute,
                    daysOfWeek = daysOfWeek,
                    enable = enable,
                    scheduleName = scheduleName
                )
                Log.i(TAG, "Rescheduled alarm $alarmId for next occurrence")
            } else {
                Log.w(TAG, "Missing data for rescheduling — alarm will not repeat")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error processing alarm", e)
        }
    }
}
