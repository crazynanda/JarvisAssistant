package com.jarvis.jarvis_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device booted, checking if wake word service should start")
            
            // Check shared preferences if wake word was enabled
            val prefs = context?.getSharedPreferences("jarvis_prefs", Context.MODE_PRIVATE)
            val wakeWordEnabled = prefs?.getBoolean("wake_word_enabled", false) ?: false
            val accessKey = prefs?.getString("picovoice_access_key", "") ?: ""
            
            if (wakeWordEnabled && accessKey.isNotEmpty()) {
                Log.d(TAG, "Starting wake word service...")
                val serviceIntent = Intent(context, WakeWordService::class.java).apply {
                    putExtra("accessKey", accessKey)
                }
                context?.startForegroundService(serviceIntent)
            }
        }
    }
}
