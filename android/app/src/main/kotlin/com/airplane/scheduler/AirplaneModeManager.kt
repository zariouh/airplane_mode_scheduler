package com.airplane.scheduler

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import com.topjohnwu.superuser.Shell

class AirplaneModeManager(private val context: Context) {

    companion object {
        private const val TAG = "AirplaneModeManager"

        @JvmStatic
        fun toggleAirplaneModeStatic(context: Context, enable: Boolean): Boolean {
            val state = if (enable) "1" else "0"
            val stateBool = if (enable) "true" else "false"
            val radioAction = if (enable) "disable" else "enable"

            return try {
                // 1. Set global setting
                execRoot("settings put global airplane_mode_on $state")

                // 2. Send the CORRECT trigger broadcast (not AIRPLANE_MODE_CHANGED)
                execRoot("am broadcast -a android.intent.action.AIRPLANE_MODE --ez state $stateBool")

                // 3. Toggle radios — only valid svc commands
                execRoot("svc wifi $radioAction")
                execRoot("svc data $radioAction")
                execRoot("svc bluetooth $radioAction")
                // No "svc telephony" — it doesn't exist; broadcast handles cellular

                Log.i(TAG, "Airplane mode toggled via root: enable=$enable")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Root-based toggle failed", e)
                false
            }
        }

        private fun execRoot(command: String) {
            val result = Shell.cmd(command).exec()
            if (!result.isSuccess) {
                Log.e(TAG, "Root command failed → $command")
                result.err.forEach { Log.e(TAG, "stderr: $it") }
            } else {
                result.out.forEach { Log.d(TAG, "stdout: $it") }
            }
        }

        @JvmStatic
        fun isAirplaneModeOnStatic(context: Context): Boolean {
            return try {
                Settings.Global.getInt(
                    context.contentResolver,
                    Settings.Global.AIRPLANE_MODE_ON
                ) == 1
            } catch (e: Exception) {
                Log.w(TAG, "Could not read airplane mode state", e)
                false
            }
        }
    }

    fun toggleAirplaneMode(enable: Boolean): Boolean =
        toggleAirplaneModeStatic(context, enable)

    fun isAirplaneModeOn(): Boolean =
        isAirplaneModeOnStatic(context)

    fun openAirplaneModeSettings() {
        try {
            context.startActivity(
                Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error opening airplane mode settings", e)
        }
    }
}
