package com.hexahelix.dq

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ALARM_CHANNEL = "alarm_service"
    private val WIDGET_CHANNEL = "com.hexahelix.dq/widget"
    private lateinit var alarmService: AlarmService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize alarm service
        alarmService = AlarmService(this)
        
        // Widget channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updatePrayerTimes") {
                val args = call.arguments as Map<*, *>
                val prefs = getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("fajr", args["fajr"] as? String ?: "5:30")
                    .putString("dhuhr", args["dhuhr"] as? String ?: "12:30")
                    .putString("asr", args["asr"] as? String ?: "16:00")
                    .putString("maghrib", args["maghrib"] as? String ?: "19:00")
                    .putString("isha", args["isha"] as? String ?: "20:30")
                    .putString("nextPrayer", args["nextPrayer"] as? String ?: "Subuh")
                    .putString("location", args["location"] as? String ?: "")
                    .apply()
                
                // Update all widget instances
                val widgetManager = AppWidgetManager.getInstance(this)
                val widgetIds = widgetManager.getAppWidgetIds(
                    ComponentName(this, PrayerTimesWidget::class.java)
                )
                for (widgetId in widgetIds) {
                    PrayerTimesWidget.updateAppWidget(this, widgetManager, widgetId)
                }
                
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
