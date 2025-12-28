package com.hexahelix.dq

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class PrayerTimesWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
            
            // Update widget views with prayer times
            views.setTextViewText(R.id.next_prayer, prefs.getString("nextPrayer", "Subuh") ?: "Subuh")
            views.setTextViewText(R.id.fajr_time, prefs.getString("fajr", "5:30") ?: "5:30")
            views.setTextViewText(R.id.dhuhr_time, prefs.getString("dhuhr", "12:30") ?: "12:30")
            views.setTextViewText(R.id.asr_time, prefs.getString("asr", "16:00") ?: "16:00")
            views.setTextViewText(R.id.maghrib_time, prefs.getString("maghrib", "19:00") ?: "19:00")
            views.setTextViewText(R.id.isha_time, prefs.getString("isha", "20:30") ?: "20:30")
            
            val location = prefs.getString("location", "")
            if (!location.isNullOrEmpty()) {
                views.setTextViewText(R.id.location_text, location)
                views.setViewVisibility(R.id.location_text, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.location_text, android.view.View.GONE)
            }
            
            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}


