package com.airplane.scheduler

import android.app.Activity
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.getSystemService

class PermissionManager(private val activity: Activity) {

    /**
     * Check if the app has exact alarm permission (Android 12+)
     */
    fun hasExactAlarmPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = activity.getSystemService<AlarmManager>()
            alarmManager?.canScheduleExactAlarms() ?: false
        } else {
            true // Permission not required on older Android versions
        }
    }

    /**
     * Request exact alarm permission by opening system settings
     */
    fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
            activity.startActivity(intent)
        }
    }

    /**
     * Check if the app is exempt from battery optimizations
     */
    fun hasBatteryOptimizationExemption(): Boolean {
        val powerManager = activity.getSystemService<PowerManager>()
        return powerManager?.isIgnoringBatteryOptimizations(activity.packageName) ?: false
    }

    /**
     * Request battery optimization exemption
     */
    fun requestBatteryOptimizationExemption() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${activity.packageName}")
        }
        activity.startActivity(intent)
    }

    /**
     * Check if the app has WRITE_SECURE_SETTINGS permission
     * This requires ADB: adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS
     */
    fun hasWriteSecureSettingsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            android.Manifest.permission.WRITE_SECURE_SETTINGS
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    /**
     * Open instructions for granting WRITE_SECURE_SETTINGS via ADB
     */
    fun openWriteSecureSettingsInstructions() {
        // Open a web page or dialog with instructions
        // For now, we'll just open the app settings
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${activity.packageName}")
        }
        activity.startActivity(intent)
    }

    /**
     * Check if notification permission is granted (Android 13+)
     */
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                activity,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true // Permission not required on older Android versions
        }
    }

    /**
     * Request notification permission (Android 13+)
     */
    fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATION_PERMISSION
            )
        }
    }

    companion object {
        const val REQUEST_NOTIFICATION_PERMISSION = 1001
    }
}
