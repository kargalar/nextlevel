package app.nextlevel


import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_widget)

            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCount = widgetData.getInt("taskCount", 0)
                val taskTitlesJson = widgetData.getString("taskTitles", "[]")

                views.setPendingIntentTemplate(R.id.task_list, taskActionTemplate(context))

                // android.util.Log.d("TaskWidgetProvider", "=== WIDGET UPDATE ===")
                // android.util.Log.d("TaskWidgetProvider", "Task count: $taskCount")

                // Header
                views.setTextViewText(R.id.header_text, "Today")
                val countLabel = if (taskCount == 1) "$taskCount task" else "$taskCount tasks"
                views.setTextViewText(R.id.task_count_text, countLabel)

                val taskTitles = JSONArray(taskTitlesJson)

                if (taskTitles.length() == 0) {
                    views.setViewVisibility(R.id.task_list, View.GONE)
                    views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                    views.setTextViewText(R.id.empty_state, "🎉 No tasks for today!")
                } else {
                    val svcIntent = Intent(context, TaskWidgetService::class.java)
                    svcIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    svcIntent.data = Uri.parse(svcIntent.toUri(Intent.URI_INTENT_SCHEME))
                    views.setRemoteAdapter(R.id.task_list, svcIntent)
                    views.setEmptyView(R.id.task_list, R.id.empty_state)

                    views.setViewVisibility(R.id.task_list, View.VISIBLE)
                    views.setViewVisibility(R.id.empty_state, View.GONE)
                    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list)
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.header_text, "Today")
                views.setTextViewText(R.id.task_count_text, "0 tasks")
                views.setViewVisibility(R.id.task_list, View.GONE)
                views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                views.setTextViewText(R.id.empty_state, "Error updating widget")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun taskActionTemplate(context: Context): PendingIntent {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }
}
