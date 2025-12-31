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
import androidx.core.app.NotificationCompat
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
            // Determine which azan file to play based on prayer
            val audioResource = when (prayerName.lowercase()) {
                "fajr" -> R.raw.azan_fajr
                else -> R.raw.azan
            }
            
            Log.d("AdhanAlarmReceiver", "Playing adhan audio for $prayerName using resource $audioResource")
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                )
                
                // Set volume to maximum for alarm
                setVolume(1.0f, 1.0f)
                
                // Set data source
                val afd = context.resources.openRawResourceFd(audioResource)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                
                // Set completion listener
                setOnCompletionListener {
                    Log.d("AdhanAlarmReceiver", "Adhan audio completed for $prayerName")
                    release()
                    mediaPlayer = null
                }
                
                // Set error listener
                setOnErrorListener { _, what, extra ->
                    Log.e("AdhanAlarmReceiver", "MediaPlayer error: what=$what, extra=$extra")
                    release()
                    mediaPlayer = null
                    true
                }
                
                // Prepare and start
                prepare()
                start()
                
                Log.d("AdhanAlarmReceiver", "Successfully started playing adhan for $prayerName")
            }
            
        } catch (e: Exception) {
            Log.e("AdhanAlarmReceiver", "Error playing adhan audio for $prayerName: ${e.message}")
            
            // Fallback to system ringtone if adhan files are not available
            try {
                Log.d("AdhanAlarmReceiver", "Falling back to system ringtone")
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setDataSource(context, android.provider.Settings.System.DEFAULT_RINGTONE_URI)
                    setVolume(1.0f, 1.0f)
                    prepare()
                    start()
                    
                    setOnCompletionListener {
                        release()
                        mediaPlayer = null
                    }
                }
            } catch (fallbackError: Exception) {
                Log.e("AdhanAlarmReceiver", "Fallback audio also failed: ${fallbackError.message}")
            }
        }
    }
    
    private fun showAdhanNotification(context: Context, prayerDisplayName: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            
            // Create notification channel for adhan
            val channelId = "adhan_channel"
            val channelName = "Azan Notifications"
            val channelDescription = "Notifications for prayer times and adhan"
            val importance = android.app.NotificationManager.IMPORTANCE_HIGH
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(channelId, channelName, importance).apply {
                    description = channelDescription
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }
            
            // Create notification
            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info) // You can use a custom icon
                .setContentTitle("Telah masuk waktu solat $prayerDisplayName")
//                .setContentText("Azan akan dimainkan sekarang")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setFullScreenIntent(null, false)
                .build()
            
            // Show notification
            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
            
            Log.d("AdhanAlarmReceiver", "Notification shown for $prayerDisplayName")
        } catch (e: Exception) {
            Log.e("AdhanAlarmReceiver", "Error showing notification: ${e.message}")
        }
    }
}
