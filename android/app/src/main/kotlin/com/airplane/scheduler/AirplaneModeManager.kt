package com.airplane.scheduler

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import com.topjohnwu.superuser.Shell

class AirplaneModeManager(private val context: Context) {

    companion object {
        private const val TAG = "AirplaneModeManager"

        /**
         * Root-based toggle using libsu
         */
        @JvmStatic
        fun toggleAirplaneModeStatic(context: Context, enable: Boolean): Boolean {
            val state = if (enable) "1" else "0"
            val stateBool = if (enable) "true" else "false"
            val radioAction = if (enable) "disable" else "enable"

            return try {
                executeRootCommand("settings put global airplane_mode_on $state")
                executeRootCommand("am broadcast -a android.intent.action.AIRPLANE_MODE_CHANGED --ez state $stateBool")
                executeRootCommand("svc data $radioAction")
                executeRootCommand("svc wifi $radioAction")
                executeRootCommand("svc bluetooth $radioAction")

                Log.i(TAG, "Root-based airplane mode toggle completed: enable=$enable")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Root-based toggle failed", e)
                false
            }
        }

        /**
         * Execute command with libsu
         */
        private fun executeRootCommand(command: String): Boolean {
            return try {
                val result = Shell.cmd(command).exec()

                if (result.isSuccess) {
                    if (result.out.isNotEmpty()) {
                        Log.d(TAG, "Root output: ${result.out.joinToString("\n")}")
                    }
                    true
                } else {
                    if (result.err.isNotEmpty()) {
                        Log.e(TAG, "Root error: ${result.err.joinToString("\n")}")
                    }
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Root command failed: $command", e)
                false
            }
        }

        /**
         * Check if root granted
         */
        @JvmStatic
        fun hasRootAccess(): Boolean {
            return Shell.isAppGrantedRoot() == true
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
                Log.e(TAG, "Fallback failed", e2)
            }
        }
    }
}
