package com.airplane.scheduler

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

data class ScheduleData(
    val id: String,
    val name: String,
    val enableHour: Int,
    val enableMinute: Int,
    val disableHour: Int,
    val disableMinute: Int,
    val daysOfWeek: List<Boolean>, // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    val enableAlarmId: Int,
    val disableAlarmId: Int
)

class DatabaseHelper(private val context: Context) {

    companion object {
        private const val TAG = "DatabaseHelper"
        private const val DB_NAME = "airplane_scheduler.db"
    }

    fun getEnabledSchedules(): List<ScheduleData> {
        val schedules = mutableListOf<ScheduleData>()

        try {
            // sqflite stores the db in the app's databases directory
            val dbPath = context.getDatabasePath(DB_NAME).absolutePath
            val db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY)

            val cursor = db.rawQuery(
                "SELECT id, name, enableTime, disableTime, daysOfWeek FROM schedules WHERE isEnabled = 1",
                null
            )

            while (cursor.moveToNext()) {
                try {
                    val id = cursor.getString(0)
                    val name = cursor.getString(1)
                    val enableTimeJson = JSONObject(cursor.getString(2))
                    val disableTimeJson = JSONObject(cursor.getString(3))
                    val daysOfWeekJson = JSONArray(cursor.getString(4))

                    val enableHour = enableTimeJson.getInt("hour")
                    val enableMinute = enableTimeJson.getInt("minute")
                    val disableHour = disableTimeJson.getInt("hour")
                    val disableMinute = disableTimeJson.getInt("minute")

                    val daysOfWeek = (0 until daysOfWeekJson.length())
                        .map { daysOfWeekJson.getBoolean(it) }

                    val enableAlarmId = "$id-enable".hashCode().let {
                        if (it == Int.MIN_VALUE) 0 else Math.abs(it)
                    } % 1000000

                    val disableAlarmId = "$id-disable".hashCode().let {
                        if (it == Int.MIN_VALUE) 0 else Math.abs(it)
                    } % 1000000

                    schedules.add(
                        ScheduleData(
                            id = id,
                            name = name,
                            enableHour = enableHour,
                            enableMinute = enableMinute,
                            disableHour = disableHour,
                            disableMinute = disableMinute,
                            daysOfWeek = daysOfWeek,
                            enableAlarmId = enableAlarmId,
                            disableAlarmId = disableAlarmId
                        )
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing schedule row", e)
                }
            }

            cursor.close()
            db.close()

            Log.i(TAG, "Loaded ${schedules.size} enabled schedules from DB")
        } catch (e: Exception) {
            Log.e(TAG, "Error reading database", e)
        }

        return schedules
    }
}
