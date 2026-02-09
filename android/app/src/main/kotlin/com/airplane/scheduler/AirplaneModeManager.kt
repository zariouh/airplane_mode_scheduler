package com.airplane.scheduler

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log

class AirplaneModeManager(private val context: Context) {

    companion object {
        private const val TAG = "AirplaneModeManager"
    }

    /**
     * Check if airplane mode is currently on
     */
    fun isAirplaneModeOn(): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.AIRPLANE_MODE_ON
            ) == 1
        } catch (e: Settings.SettingNotFoundException) {
            Log.e(TAG, "Error reading airplane mode state", e)
            false
        }
    }

    /**
     * Toggle airplane mode on/off
     * Requires WRITE_SECURE_SETTINGS permission (granted via ADB)
     * 
     * ADB command: adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS
     */
    fun toggleAirplaneMode(enable: Boolean): Boolean {
        return try {
            // Check if we have the required permission
            if (!hasWriteSecureSettingsPermission()) {
                Log.w(TAG, "WRITE_SECURE_SETTINGS permission not granted")
                return false
            }

            // Set airplane mode state
            Settings.Global.putInt(
                context.contentResolver,
                Settings.Global.AIRPLANE_MODE_ON,
                if (enable) 1 else 0
            )

            // Broadcast the change
            val intent = Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED).apply {
                putExtra("state", enable)
            }
            context.sendBroadcast(intent)

            Log.i(TAG, "Airplane mode toggled: $enable")
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: WRITE_SECURE_SETTINGS permission required", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error toggling airplane mode", e)
            false
        }
    }

    /**
     * Open airplane mode settings page
     * This is a fallback when direct toggle is not possible
     */
    fun openAirplaneModeSettings() {
        try {
            val intent = Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening airplane mode settings", e)
            // Fallback to wireless settings
            try {
                val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } catch (e2: Exception) {
                Log.e(TAG, "Error opening wireless settings", e2)
            }
        }
    }

    /**
     * Check if we have WRITE_SECURE_SETTINGS permission
     */
    private fun hasWriteSecureSettingsPermission(): Boolean {
        return context.checkSelfPermission(
            android.Manifest.permission.WRITE_SECURE_SETTINGS
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }
}
