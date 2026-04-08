package com.airplane.scheduler

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import java.util.Calendar

class AlarmScheduler(private val context: Context) {

    companion object {
        private const val TAG = "AlarmScheduler"
    }

    fun scheduleAlarm(
        alarmId: Int,
        hour: Int,
        minute: Int,
        daysOfWeek: List<Boolean>,
        enable: Boolean,
        scheduleName: String
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val now = Calendar.getInstance()
        var scheduled = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // If time already passed today, start from tomorrow
        if (scheduled.before(now)) {
            scheduled.add(Calendar.DAY_OF_YEAR, 1)
        }

        // Advance to the next enabled day of week
        // daysOfWeek is Mon=index 0 ... Sun=index 6
        // Calendar.DAY_OF_WEEK: Mon=2 ... Sun=1, so we map accordingly
        var attempts = 0
        while (attempts < 7) {
            val calDay = scheduled.get(Calendar.DAY_OF_WEEK) // 1=Sun, 2=Mon...7=Sat
            val idx = if (calDay == Calendar.SUNDAY) 6 else calDay - 2
            if (daysOfWeek[idx]) break
            scheduled.add(Calendar.DAY_OF_YEAR, 1)
            attempts++
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(AlarmReceiver.EXTRA_ENABLE, enable)
            putExtra(AlarmReceiver.EXTRA_SCHEDULE_NAME, scheduleName)
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_HOUR, hour)
            putExtra(AlarmReceiver.EXTRA_MINUTE, minute)
            putExtra(AlarmReceiver.EXTRA_DAYS_OF_WEEK, daysOfWeek.joinToString(","))
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            scheduled.timeInMillis,
            pendingIntent
        )

        Log.i(TAG, "Scheduled alarm $alarmId for ${scheduled.time}, enable=$enable")
    }

    fun cancelAlarm(alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.i(TAG, "Cancelled alarm $alarmId")
    }
}
