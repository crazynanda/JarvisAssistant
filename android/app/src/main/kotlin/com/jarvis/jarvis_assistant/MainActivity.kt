package com.jarvis.jarvis_assistant

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    
    companion object {
        const val TAG = "MainActivity"
        const val WAKE_WORD_CHANNEL = "com.jarvis/wake_word"
        const val WAKE_WORD_EVENT_CHANNEL = "com.jarvis/wake_word_events"
    }
    
    private var wakeWordActivated = false
    private var eventSink: EventChannel.EventSink? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if launched by wake word
        wakeWordActivated = intent?.getBooleanExtra("wakeWordActivated", false) ?: false
        if (wakeWordActivated) {
            Log.d(TAG, "App launched by wake word!")
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Check if app brought to foreground by wake word
        val activated = intent.getBooleanExtra("wakeWordActivated", false)
        if (activated) {
            Log.d(TAG, "Wake word detected - notifying Flutter")
            eventSink?.success(mapOf("event" to "wake_word_detected"))
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method channel for controlling wake word service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_WORD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startWakeWordService" -> {
                        val accessKey = call.argument<String>("accessKey") ?: ""
                        startWakeWordService(accessKey)
                        result.success(true)
                    }
                    "stopWakeWordService" -> {
                        stopWakeWordService()
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        result.success(WakeWordService.isRunning)
                        // result.success(false)
                    }
                    "saveAccessKey" -> {
                        val accessKey = call.argument<String>("accessKey") ?: ""
                        saveAccessKey(accessKey)
                        result.success(true)
                    }
                    "wasLaunchedByWakeWord" -> {
                        result.success(wakeWordActivated)
                        wakeWordActivated = false // Reset after reading
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Event channel for wake word detection events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_WORD_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "Event channel listening")
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "Event channel cancelled")
                }
            })
    }
    
    private fun startWakeWordService(accessKey: String) {
        Log.d(TAG, "Starting wake word service")
        
        val serviceIntent = Intent(this, WakeWordService::class.java).apply {
            putExtra("accessKey", accessKey)
        }
        startForegroundService(serviceIntent)
        
        // Save state for boot receiver
        val prefs = getSharedPreferences("jarvis_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("wake_word_enabled", true)
            .putString("picovoice_access_key", accessKey)
            .apply()
    }
    
    private fun stopWakeWordService() {
        Log.d(TAG, "Stopping wake word service")
        
        val serviceIntent = Intent(this, WakeWordService::class.java)
        stopService(serviceIntent)
        
        // Update state
        val prefs = getSharedPreferences("jarvis_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("wake_word_enabled", false)
            .apply()
    }
    
    private fun saveAccessKey(accessKey: String) {
        val prefs = getSharedPreferences("jarvis_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("picovoice_access_key", accessKey)
            .apply()
    }
}
