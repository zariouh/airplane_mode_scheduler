package com.airplane.scheduler

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import eu.chainfire.libsuperuser.Shell

class AirplaneModeManager(private val context: Context) {

    companion object {
        private const val TAG = "AirplaneModeManager"

        /**
         * Root-based toggle using su shell commands (adapted from libsuperuser)
         * This bypasses all broadcast and radio restrictions on LineageOS
         */
        @JvmStatic
        fun toggleAirplaneModeStatic(context: Context, enable: Boolean): Boolean {
            val state = if (enable) "1" else "0"
            val stateBool = if (enable) "true" else "false"
            val radioAction = if (enable) "disable" else "enable"

            try {
                // 1. Set global airplane mode setting (affects UI/notification)
                executeRootCommand("settings put global airplane_mode_on $state")

                // 2. Send the airplane mode broadcast via root shell
                val broadcastCmd = "am broadcast -a android.intent.action.AIRPLANE_MODE_CHANGED --ez state $stateBool"
                executeRootCommand(broadcastCmd)

                // 3. Force-disable/enable radios (this is what usually fixes the "calls still work" issue)
                executeRootCommand("svc data $radioAction")
                executeRootCommand("svc wifi $radioAction")
                executeRootCommand("svc bluetooth $radioAction")

                Log.i(TAG, "Root-based airplane mode toggle completed: enable=$enable")
                return true
            } catch (e: Exception) {
                Log.e(TAG, "Root-based toggle failed", e)
                return false
            }
        }

        /**
         * Execute a command with root privileges using libsuperuser
         * Logs output and errors for debugging
         */
        private fun executeRootCommand(command: String): Boolean {
            val stdout = ArrayList<String>()
            val stderr = ArrayList<String>()
            try {
                Shell.Pool.SU.run(command, stdout, stderr, true)  // true = wait for completion
                if (stdout.isNotEmpty()) {
                    Log.d(TAG, "Root command output: ${stdout.joinToString("\n")}")
                }
                if (stderr.isNotEmpty()) {
                    Log.e(TAG, "Root command error: ${stderr.joinToString("\n")}")
                    return false
                }
                return true
            } catch (e: Shell.ShellDiedException) {
                Log.e(TAG, "Shell died during root command: $command", e)
                return false
            } catch (e: Exception) {
                Log.e(TAG, "Failed to run root command: $command", e)
                return false
            }
        }

        /**
         * Check if root is available (triggers popup if not granted)
         */
        @JvmStatic
        fun hasRootAccess(): Boolean {
            return Shell.SU.available()
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

    // Public instance methods (used from Flutter via channel)
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
