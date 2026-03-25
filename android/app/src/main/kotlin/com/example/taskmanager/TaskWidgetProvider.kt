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

class TaskWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, widgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget", e)
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
                val tasks = getActiveTasks(context)
                if (tasks.isNotEmpty()) {
                    val current = getCurrentIndex(context, widgetId)
                    val newIndex = (current - 1 + tasks.size) % tasks.size
                    saveCurrentIndex(context, widgetId, newIndex)
                    updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
                }
            }
            ACTION_NEXT -> {
                val tasks = getActiveTasks(context)
                if (tasks.isNotEmpty()) {
                    val current = getCurrentIndex(context, widgetId)
                    val newIndex = (current + 1) % tasks.size
                    saveCurrentIndex(context, widgetId, newIndex)
                    updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
                }
            }
        }
    }

    companion object {
        private const val TAG = "TaskWidget"
        const val ACTION_PREV = "com.example.taskmanager.WIDGET_PREV"
        const val ACTION_NEXT = "com.example.taskmanager.WIDGET_NEXT"
        private const val PREF_INDEX_PREFIX = "widget_index_"

        private fun getCurrentIndex(context: Context, widgetId: Int): Int {
            val prefs = context.getSharedPreferences("TaskWidgetPrefs", Context.MODE_PRIVATE)
            return prefs.getInt("$PREF_INDEX_PREFIX$widgetId", 0)
        }

        private fun saveCurrentIndex(context: Context, widgetId: Int, index: Int) {
            val prefs = context.getSharedPreferences("TaskWidgetPrefs", Context.MODE_PRIVATE)
            prefs.edit().putInt("$PREF_INDEX_PREFIX$widgetId", index).apply()
        }

        fun getActiveTasks(context: Context): List<JSONObject> {
            return try {
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE
                )
                val rawValue = prefs.getString("flutter.tasks", null) ?: return emptyList()
                val jsonStart = rawValue.indexOf('[')
                if (jsonStart == -1) return emptyList()
                val arr = JSONArray(rawValue.substring(jsonStart))
                val result = mutableListOf<JSONObject>()
                for (i in 0 until arr.length()) {
                    val task = JSONObject(arr.getString(i))
                    if (!task.optBoolean("isCompleted", false)) {
                        result.add(task)
                    }
                }
                result
            } catch (e: Exception) {
                Log.e(TAG, "Error reading tasks", e)
                emptyList()
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.task_widget)

            // ── Tap widget root → open app ──
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPending = PendingIntent.getActivity(
                context, widgetId, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPending)

            // ── Prev button ──
            val prevIntent = Intent(context, TaskWidgetProvider::class.java).apply {
                action = ACTION_PREV
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val prevPending = PendingIntent.getBroadcast(
                context, widgetId * 10 + 1, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prev, prevPending)

            // ── Next button ──
            val nextIntent = Intent(context, TaskWidgetProvider::class.java).apply {
                action = ACTION_NEXT
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val nextPending = PendingIntent.getBroadcast(
                context, widgetId * 10 + 2, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_next, nextPending)

            // ── Task content ──
            val tasks = getActiveTasks(context)
            if (tasks.isEmpty()) {
                views.setTextViewText(R.id.widget_task_title, "No active tasks!")
                views.setTextViewText(R.id.widget_task_date, "")
            } else {
                // Clamp index in case tasks were deleted
                var index = getCurrentIndex(context, widgetId)
                if (index >= tasks.size) {
                    index = 0
                    saveCurrentIndex(context, widgetId, 0)
                }
                val task = tasks[index]
                val title = task.optString("title", "Task")
                val endDate = task.optString("endDate", "")
                val dateStr = if (endDate.isNotEmpty()) "Due ${formatDate(endDate)}" else ""

                views.setTextViewText(R.id.widget_task_title, title)
                views.setTextViewText(R.id.widget_task_date, dateStr)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Widget visual pushed to launcher: $widgetId")
        }

        private fun formatDate(isoDate: String): String {
            if (isoDate.isEmpty()) return ""
            return try {
                val months = listOf(
                    "Jan","Feb","Mar","Apr","May","Jun",
                    "Jul","Aug","Sep","Oct","Nov","Dec"
                )
                val parts = isoDate.split("-")
                val month = parts[1].toInt()
                val day = parts[2].substring(0, 2).toInt()
                "$day ${months[month - 1]}"
            } catch (e: Exception) { "" }
        }
    }
}