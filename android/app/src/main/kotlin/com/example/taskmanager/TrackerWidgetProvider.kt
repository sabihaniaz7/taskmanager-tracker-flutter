package com.example.taskmanager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.example.taskmanager.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class TrackerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, widgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating tracker widget", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        when (intent.action) {
            ACTION_PREV -> {
                val trackers = getActiveTrackers(context)
                if (trackers.isNotEmpty()) {
                    val current = getCurrentIndex(context, widgetId)
                    val newIndex = (current - 1 + trackers.size) % trackers.size
                    saveCurrentIndex(context, widgetId, newIndex)
                    updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
                }
            }
            ACTION_NEXT -> {
                val trackers = getActiveTrackers(context)
                if (trackers.isNotEmpty()) {
                    val current = getCurrentIndex(context, widgetId)
                    val newIndex = (current + 1) % trackers.size
                    saveCurrentIndex(context, widgetId, newIndex)
                    updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
                }
            }
        }
    }

    companion object {
        private const val TAG = "TrackerWidget"
        const val ACTION_PREV = "com.example.taskmanager.TRACKER_WIDGET_PREV"
        const val ACTION_NEXT = "com.example.taskmanager.TRACKER_WIDGET_NEXT"
        private const val PREF_INDEX_PREFIX = "tracker_widget_index_"

        private fun getCurrentIndex(context: Context, widgetId: Int): Int {
            val prefs = context.getSharedPreferences("TrackerWidgetPrefs", Context.MODE_PRIVATE)
            return prefs.getInt("$PREF_INDEX_PREFIX$widgetId", 0)
        }

        private fun saveCurrentIndex(context: Context, widgetId: Int, index: Int) {
            val prefs = context.getSharedPreferences("TrackerWidgetPrefs", Context.MODE_PRIVATE)
            prefs.edit().putInt("$PREF_INDEX_PREFIX$widgetId", index).apply()
        }

        fun getActiveTrackers(context: Context): List<JSONObject> {
            return try {
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE
                )
                // TrackerProvider saves under key 'tracking_entries' as a StringList
                // Flutter StringList is stored as a JSONArray string with prefix
                val rawValue = prefs.getString("flutter.tracking_entries", null)
                    ?: return emptyList()

                // Flutter stores StringList as JSON array: ["json1","json2",...]
                val jsonStart = rawValue.indexOf('[')
                if (jsonStart == -1) return emptyList()

                val arr = JSONArray(rawValue.substring(jsonStart))
                val result = mutableListOf<JSONObject>()
                for (i in 0 until arr.length()) {
                    val trackerJson = arr.getString(i)
                    val tracker = JSONObject(trackerJson)
                    if (!tracker.optBoolean("isArchived", false)) {
                        result.add(tracker)
                    }
                }
                result
            } catch (e: Exception) {
                Log.e(TAG, "Error reading trackers: ${e.message}")
                emptyList()
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.tracker_widget)

            // ── Tap root → open app ──
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPending = PendingIntent.getActivity(
                context, widgetId + 5000, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tracker_widget_root, openPending)

            // ── Prev button ──
            val prevIntent = Intent(context, TrackerWidgetProvider::class.java).apply {
                action = ACTION_PREV
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val prevPending = PendingIntent.getBroadcast(
                context, widgetId * 10 + 3, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tracker_widget_prev, prevPending)

            // ── Next button ──
            val nextIntent = Intent(context, TrackerWidgetProvider::class.java).apply {
                action = ACTION_NEXT
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val nextPending = PendingIntent.getBroadcast(
                context, widgetId * 10 + 4, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tracker_widget_next, nextPending)

            // ── Tracker content ──
            val trackers = getActiveTrackers(context)
            if (trackers.isEmpty()) {
                views.setTextViewText(R.id.tracker_widget_title, "No Goals to track yet!")
                views.setTextViewText(R.id.tracker_widget_status, "")
                views.setTextViewText(R.id.tracker_widget_streak, "")
            } else {
                var index = getCurrentIndex(context, widgetId)
                if (index >= trackers.size) {
                    index = 0
                    saveCurrentIndex(context, widgetId, 0)
                }
                val tracker = trackers[index]
                val title = tracker.optString("title", "Tracker")
                val completedDates = tracker.optJSONArray("completedDates")
                val todayKey = todayDateKey()
                var doneToday = false
                if (completedDates != null) {
                    for (i in 0 until completedDates.length()) {
                        if (completedDates.getString(i) == todayKey) {
                            doneToday = true
                            break
                        }
                    }
                }

                // Streak calculation
                val streak = calculateStreak(tracker)

                views.setTextViewText(R.id.tracker_widget_title, title)
                views.setTextViewText(
                    R.id.tracker_widget_status,
                    if (doneToday) "Done today!" else "Not done yet!"
                )
                views.setTextViewText(
                    R.id.tracker_widget_streak,
                    if (streak > 0) "🔥 $streak" else ""
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Tracker widget pushed to launcher: $widgetId")
        }

        private fun todayDateKey(): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            return sdf.format(Date())
        }

        private fun calculateStreak(tracker: JSONObject): Int {
            val completedDates = tracker.optJSONArray("completedDates") ?: return 0
            val datesSet = mutableSetOf<String>()
            for (i in 0 until completedDates.length()) {
                datesSet.add(completedDates.getString(i))
            }
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            var streak = 0
            val cal = Calendar.getInstance()
            while (true) {
                val key = sdf.format(cal.time)
                if (datesSet.contains(key)) {
                    streak++
                    cal.add(Calendar.DAY_OF_YEAR, -1)
                } else break
            }
            return streak
        }
    }
}