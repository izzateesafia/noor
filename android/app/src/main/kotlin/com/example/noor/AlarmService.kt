package com.hexahelix.dq

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class AlarmService(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val channel = MethodChannel(FlutterEngine(context).dartExecutor.binaryMessenger, "alarm_service")
    
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: 0
                    val scheduledTime = call.argument<Long>("scheduledTime") ?: 0L
                    val prayerName = call.argument<String>("prayerName") ?: "Dhuhr"
                    val prayerDisplayName = call.argument<String>("prayerDisplayName") ?: "Zuhur"
                    
                    scheduleAlarm(alarmId, scheduledTime, prayerName, prayerDisplayName)
                    result.success("Alarm scheduled")
                }
                "cancelAllAlarms" -> {
                    cancelAllAlarms()
                    result.success("All alarms cancelled")
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun scheduleAlarm(alarmId: Int, scheduledTime: Long, prayerName: String, prayerDisplayName: String) {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra("prayerName", prayerName)
            putExtra("prayerDisplayName", prayerDisplayName)
            putExtra("alarmId", alarmId)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val triggerTime = scheduledTime
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }
        
        Log.d("AlarmService", "Alarm scheduled for $prayerDisplayName at ${Date(triggerTime)}")
    }
    
    private fun cancelAllAlarms() {
        // Cancel all pending intents
        for (i in 1..100) { // Cancel alarms with IDs 1-100
            val intent = Intent(context, AdhanAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                i,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let { alarmManager.cancel(it) }
        }
        Log.d("AlarmService", "All alarms cancelled")
    }
}

class AdhanAlarmReceiver : BroadcastReceiver() {
    private var mediaPlayer: MediaPlayer? = null
    
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayerName") ?: "Dhuhr"
        val prayerDisplayName = intent.getStringExtra("prayerDisplayName") ?: "Zuhur"
        val alarmId = intent.getIntExtra("alarmId", 0)
        
        Log.d("AdhanAlarmReceiver", "Alarm triggered for $prayerDisplayName (ID: $alarmId)")
        
        // Play adhan audio
        playAdhanAudio(context, prayerName)
        
        // Show notification
        showAdhanNotification(context, prayerDisplayName)
    }
    
    private fun playAdhanAudio(context: Context, prayerName: String) {
        try {
            // For now, we'll use a simple beep sound
            // In production, you'd add the actual azan audio files to res/raw/
            val audioResource = android.R.raw.ringtone // Fallback to system ringtone
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setDataSource(context.resources.openRawResourceFd(audioResource))
                prepare()
                start()
                
                setOnCompletionListener {
                    release()
                    mediaPlayer = null
                }
            }
            
            Log.d("AdhanAlarmReceiver", "Playing adhan audio for $prayerName")
        } catch (e: Exception) {
            Log.e("AdhanAlarmReceiver", "Error playing adhan audio: ${e.message}")
        }
    }
    
    private fun showAdhanNotification(context: Context, prayerDisplayName: String) {
        // This would show a notification when the alarm fires
        // Implementation depends on your notification system
        Log.d("AdhanAlarmReceiver", "Showing notification for $prayerDisplayName")
    }
}
