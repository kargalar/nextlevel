package app.nextlevel

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class TaskTemplateWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, it) }
        val today = Calendar.getInstance().let {
            "${it.get(Calendar.YEAR)}-${it.get(Calendar.MONTH) + 1}-${it.get(Calendar.DAY_OF_MONTH)}"
        }
        if (ids.isNotEmpty() &&
            HomeWidgetPlugin.getData(context).getString("taskTemplateWidgetDay", null) != today
        ) {
            HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("nextlevel://task-template?action=refresh"),
            ).send()
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) = update(context, id)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != PINNED) return
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val templateId = intent.getIntExtra(TEMPLATE_ID, -1)
        if (id >= 0 && templateId >= 0) configure(context, id, templateId)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val editor = HomeWidgetPlugin.getData(context).edit()
        ids.forEach { editor.remove("$BINDING_PREFIX$it") }
        editor.apply()
    }

    override fun onRestored(context: Context, oldIds: IntArray, newIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val editor = prefs.edit()
        oldIds.zip(newIds).forEach { (old, new) ->
            editor.putInt("$BINDING_PREFIX$new", prefs.getInt("$BINDING_PREFIX$old", -1))
            editor.remove("$BINDING_PREFIX$old")
        }
        editor.apply()
        newIds.forEach { update(context, it) }
    }

    companion object {
        const val TEMPLATE_ID = "templateId"
        private const val PINNED = "app.nextlevel.TASK_TEMPLATE_WIDGET_PINNED"
        private const val BINDING_PREFIX = "taskTemplateWidgetBinding_"

        fun templates(context: Context): List<JSONObject> {
            val raw = HomeWidgetPlugin.getData(context).getString(DATA_KEY, "[]")
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { array.getJSONObject(it) }
            } catch (_: Exception) {
                emptyList()
            }
        }

        fun pin(context: Context, templateId: Int): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            if (templates(context).none { it.optInt("id", -1) == templateId }) return false
            val callback = Intent(context, TaskTemplateWidgetProvider::class.java).apply {
                action = PINNED
                data = Uri.parse("nextlevel://pin-task-template/$templateId/${System.nanoTime()}")
                putExtra(TEMPLATE_ID, templateId)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            return manager.requestPinAppWidget(
                ComponentName(context, TaskTemplateWidgetProvider::class.java),
                null,
                PendingIntent.getBroadcast(context, 0, callback, flags),
            )
        }

        fun configure(context: Context, id: Int, templateId: Int) {
            HomeWidgetPlugin.getData(context).edit()
                .putInt("$BINDING_PREFIX$id", templateId)
                .apply()
            update(context, id)
        }

        fun update(context: Context, id: Int) {
            val prefs = HomeWidgetPlugin.getData(context)
            val templateId = prefs.getInt("$BINDING_PREFIX$id", -1)
            val template = templates(context).firstOrNull { it.optInt("id", -1) == templateId }
            val views = RemoteViews(context.packageName, R.layout.task_template_widget)
            var title = template?.optString("title")
                ?: context.getString(R.string.task_template_widget_name)
            var symbol = "+"
            var status = context.getString(R.string.task_template_widget_unavailable)
            val running = template?.optBoolean("running") == true
            views.setViewVisibility(R.id.task_template_clock, View.GONE)
            views.setViewVisibility(R.id.task_template_progress, View.VISIBLE)

            if (template != null) {
                val available = template.optBoolean("available")
                when (template.optString("type")) {
                    "CHECKBOX" -> {
                        val done = template.optBoolean("done")
                        symbol = if (done) "☑" else "☐"
                        status = if (!available) {
                            context.getString(R.string.task_template_widget_create)
                        } else {
                            context.getString(
                                if (done) R.string.task_template_widget_undo
                                else R.string.task_template_widget_complete,
                            )
                        }
                    }
                    "COUNTER" -> {
                        symbol = "+1"
                        status = if (!available) {
                            context.getString(R.string.task_template_widget_create)
                        } else {
                            "${template.optInt("count")}/${template.optInt("target")}"
                        }
                    }
                    "TIMER" -> {
                        symbol = if (running) "Ⅱ" else "▶"
                        status = if (!available) {
                            context.getString(R.string.task_template_widget_create)
                        } else {
                            context.getString(
                                if (running) R.string.task_template_widget_pause
                                else R.string.task_template_widget_start,
                            )
                        }
                        val startedAt = template.optLong("startedAt", 0)
                        val seconds = if (running && startedAt > 0) {
                            template.optLong("startSeconds") +
                                (System.currentTimeMillis() - startedAt).coerceAtLeast(0) / 1000
                        } else template.optLong("seconds")
                        if (available) {
                            views.setChronometer(
                                R.id.task_template_clock,
                                SystemClock.elapsedRealtime() - seconds * 1000,
                                null,
                                running,
                            )
                            views.setViewVisibility(R.id.task_template_clock, View.VISIBLE)
                            views.setViewVisibility(R.id.task_template_progress, View.GONE)
                        }
                    }
                }
            }

            var error = prefs.getString("taskTemplateWidgetError_$templateId", null)
            if (error == "permission") {
                val notificationsGranted = Build.VERSION.SDK_INT < 33 ||
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                    android.content.pm.PackageManager.PERMISSION_GRANTED
                val alarmsGranted = Build.VERSION.SDK_INT < 31 ||
                    (context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager)
                        .canScheduleExactAlarms()
                if (notificationsGranted && alarmsGranted) {
                    prefs.edit().remove("taskTemplateWidgetError_$templateId").apply()
                    error = null
                }
            }
            if (error != null) {
                status = context.getString(
                    if (error == "permission") R.string.task_template_widget_permission
                    else R.string.task_template_widget_error,
                )
                views.setViewVisibility(R.id.task_template_clock, View.GONE)
                views.setViewVisibility(R.id.task_template_progress, View.VISIBLE)
            }

            views.setTextViewText(R.id.task_template_title, title)
            views.setTextViewText(R.id.task_template_action, symbol)
            views.setTextViewText(R.id.task_template_progress, status)
            views.setContentDescription(R.id.task_template_button, "$title, $status")
            val click = if (template == null || error == "permission") {
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            } else {
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("nextlevel://task-template?action=task_template_toggle&templateId=$templateId"),
                )
            }
            views.setOnClickPendingIntent(R.id.task_template_button, click)
            AppWidgetManager.getInstance(context).updateAppWidget(id, views)
        }

        private const val DATA_KEY = "taskTemplateWidgets"
    }
}
