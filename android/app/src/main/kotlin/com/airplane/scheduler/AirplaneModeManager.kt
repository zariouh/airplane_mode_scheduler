package com.airplane.scheduler

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader

class AirplaneModeManager(private val context: Context) {

    companion object {
        private const val TAG = "AirplaneModeManager"

        @JvmStatic
        fun toggleAirplaneModeStatic(context: Context, enable: Boolean): Boolean {
            val state = if (enable) "1" else "0"
            val stateBool = if (enable) "true" else "false"
            val radioAction = if (enable) "disable" else "enable"

            try {
                // 1. Set global airplane mode setting (affects UI/notification)
                execRoot("settings put global airplane_mode_on $state")

                // 2. Send the airplane mode broadcast via root shell
                val broadcastCmd = "am broadcast -a android.intent.action.AIRPLANE_MODE_CHANGED --ez state $stateBool"
                execRoot(broadcastCmd)

                // 3. Force-disable/enable radios (added telephony for calls/SIM)
                execRoot("svc data $radioAction")
                execRoot("svc wifi $radioAction")
                execRoot("svc bluetooth $radioAction")
                execRoot("svc telephony $radioAction") // NEW: Disables/enables cellular radio

                Log.i(TAG, "Root-based airplane mode toggle completed: enable=$enable")
                return true
            } catch (e: Exception) {
                Log.e(TAG, "Root-based toggle failed", e)
                return false
            }
        }

        private fun execRoot(command: String) {
            try {
                val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
                // Capture output and error
                val output = BufferedReader(InputStreamReader(process.inputStream)).readText()
                val error = BufferedReader(InputStreamReader(process.errorStream)).readText()
                process.waitFor()
                val exitCode = process.exitValue()
                if (exitCode == 0) {
                    if (output.isNotBlank()) {
                        Log.d(TAG, "Root command output: $output")
                    }
                } else {
                    Log.e(TAG, "Root command failed (exit $exitCode) → $command")
                    if (error.isNotBlank()) Log.e(TAG, "Error: $error")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to run root command: $command", e)
            }
        }

        @JvmStatic
        fun isAirplaneModeOnStatic(context: Context): Boolean {
            return try {
                Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON) == 1
            } catch (e: Exception) {
                Log.w(TAG, "Could not read airplane mode state", e)
                false
            }
        }
    }

    fun toggleAirplaneMode(enable: Boolean): Boolean {
        return toggleAirplaneModeStatic(context, enable)
    }

    fun isAirplaneModeOn(): Boolean {
        return isAirplaneModeOnStatic(context)
    }

    fun openAirplaneModeSettings() {
        try {
            val intent = Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening airplane mode settings", e)
            try {
                val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } catch (e2: Exception) {
                Log.e(TAG, "Fallback to wireless settings failed", e2)
            }
        }
    }
}
