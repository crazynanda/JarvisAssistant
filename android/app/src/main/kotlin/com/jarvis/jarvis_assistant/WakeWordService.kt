package com.jarvis.jarvis_assistant

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import ai.picovoice.porcupine.*

class WakeWordService : Service() {
    
    companion object {
        const val TAG = "WakeWordService"
        const val CHANNEL_ID = "jarvis_wake_word_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.jarvis.STOP_WAKE_WORD"
        
        var isRunning = false
            private set
    }
    
    private var porcupineManager: PorcupineManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "WakeWordService onCreate")
        createNotificationChannel()
        acquireWakeLock()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "WakeWordService onStartCommand")
        
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        
        val accessKey = intent?.getStringExtra("accessKey") ?: ""
        
        if (accessKey.isEmpty()) {
            Log.e(TAG, "No Picovoice access key provided")
            stopSelf()
            return START_NOT_STICKY
        }
        
        startForeground(NOTIFICATION_ID, createNotification())
        startWakeWordDetection(accessKey)
        isRunning = true
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "WakeWordService onDestroy")
        stopWakeWordDetection()
        releaseWakeLock()
        isRunning = false
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "J.A.R.V.I.S Wake Word",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Listening for 'JARVIS' wake word"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(this, WakeWordService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("J.A.R.V.I.S Active")
            .setContentText("Listening for wake word...")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openAppPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build()
    }
    
    private fun startWakeWordDetection(accessKey: String) {
        try {
            // Use built-in "jarvis" keyword
            porcupineManager = PorcupineManager.Builder()
                .setAccessKey(accessKey)
                .setKeyword(Porcupine.BuiltInKeyword.JARVIS)
                .setSensitivity(0.7f)
                .build(this) { keywordIndex ->
                    Log.d(TAG, "Wake word detected! Index: $keywordIndex")
                    onWakeWordDetected()
                }
            
            porcupineManager?.start()
            Log.d(TAG, "Wake word detection started")
            
        } catch (e: PorcupineException) {
            Log.e(TAG, "Failed to start Porcupine: ${e.message}")
            stopSelf()
        }
    }
    
    private fun stopWakeWordDetection() {
        try {
            porcupineManager?.stop()
            porcupineManager?.delete()
            porcupineManager = null
            Log.d(TAG, "Wake word detection stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Porcupine: ${e.message}")
        }
    }
    
    private fun onWakeWordDetected() {
        Log.d(TAG, "JARVIS wake word detected!")
        
        // Send broadcast to Flutter
        val intent = Intent("com.jarvis.WAKE_WORD_DETECTED")
        sendBroadcast(intent)
        
        // Bring app to foreground
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("wakeWordActivated", true)
        }
        startActivity(launchIntent)
    }
    
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "JarvisAssistant::WakeWordLock"
        )
        wakeLock?.acquire()
        Log.d(TAG, "Wake lock acquired")
    }
    
    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "Wake lock released")
            }
        }
        wakeLock = null
    }
}
