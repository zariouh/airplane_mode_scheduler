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
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON") return

        Log.i(TAG, "Boot completed - rescheduling alarms natively")

        Thread {
            try {
                val db = DatabaseHelper(context)
                val alarmScheduler = AlarmScheduler(context)
                val schedules = db.getEnabledSchedules()

                for (schedule in schedules) {
                    alarmScheduler.scheduleAlarm(
                        alarmId = schedule.enableAlarmId,
                        hour = schedule.enableHour,
                        minute = schedule.enableMinute,
                        daysOfWeek = schedule.daysOfWeek,
                        enable = true,
                        scheduleName = schedule.name
                    )
                    alarmScheduler.scheduleAlarm(
                        alarmId = schedule.disableAlarmId,
                        hour = schedule.disableHour,
                        minute = schedule.disableMinute,
                        daysOfWeek = schedule.daysOfWeek,
                        enable = false,
                        scheduleName = schedule.name
                    )
                    Log.i(TAG, "Rescheduled: ${schedule.name}")
                }

                Log.i(TAG, "Rescheduled ${schedules.size} schedules after boot")
            } catch (e: Exception) {
                Log.e(TAG, "Error rescheduling on boot", e)
            }
        }.start()
    }
}
