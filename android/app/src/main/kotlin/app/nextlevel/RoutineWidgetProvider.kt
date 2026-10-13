package app.nextlevel

import android.app.PendingIntent
import android.app.AlarmManager
import android.content.pm.PackageManager
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

class RoutineWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, it) }
        val today = Calendar.getInstance().let {
            "${it.get(Calendar.YEAR)}-${it.get(Calendar.MONTH) + 1}-${it.get(Calendar.DAY_OF_MONTH)}"
        }
        if (ids.isNotEmpty() && HomeWidgetPlugin.getData(context).getString("routineWidgetDay", null) != today) {
            HomeWidgetBackgroundIntent.getBroadcast(context,
                Uri.parse("nextlevel://routine?action=refresh")).send()
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager,
        id: Int, options: Bundle) = update(context, id)

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = HomeWidgetPlugin.getData(context)
        prefs.all.filterKeys { it.startsWith("widgetAlarmAutoStop_") }.forEach { (key, value) ->
            val alarmId = key.removePrefix("widgetAlarmAutoStop_").toIntOrNull()
            val stopAt = value.toString().toLongOrNull()
            if (alarmId != null && stopAt != null) {
                if (stopAt == 0L) AlarmAutoStopScheduler.cancel(context, alarmId)
                else AlarmAutoStopScheduler.schedule(context, alarmId, stopAt)
            }
            prefs.edit().remove(key).apply()
        }
        super.onReceive(context, intent)
        if (intent.action == PINNED) {
            val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
            val routineId = intent.getIntExtra(ROUTINE_ID, -1)
            if (id >= 0 && routineId >= 0) configure(context, id, routineId)
        }
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
        const val ROUTINE_ID = "routineId"
        private const val PINNED = "app.nextlevel.ROUTINE_WIDGET_PINNED"
        private const val BINDING_PREFIX = "routineWidgetBinding_"

        fun routines(context: Context): List<JSONObject> {
            val raw = HomeWidgetPlugin.getData(context).getString("routineWidgets", "[]")
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { array.getJSONObject(it) }
            } catch (_: Exception) { emptyList() }
        }

        fun pin(context: Context, routineId: Int): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            if (routines(context).none { it.optInt("id", -1) == routineId }) return false
            val callback = Intent(context, RoutineWidgetProvider::class.java).apply {
                action = PINNED
                data = Uri.parse("nextlevel://pin-routine/$routineId/${System.nanoTime()}")
                putExtra(ROUTINE_ID, routineId)
            }
            // The launcher fills in EXTRA_APPWIDGET_ID after the user accepts.
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            return manager.requestPinAppWidget(ComponentName(context, RoutineWidgetProvider::class.java),
                null, PendingIntent.getBroadcast(context, 0, callback, flags))
        }

        fun configure(context: Context, id: Int, routineId: Int) {
            HomeWidgetPlugin.getData(context).edit()
                .putInt("$BINDING_PREFIX$id", routineId).apply()
            update(context, id)
        }

        fun update(context: Context, id: Int) {
            val prefs = HomeWidgetPlugin.getData(context)
            val routineId = prefs.getInt("$BINDING_PREFIX$id", -1)
            val routine = routines(context).firstOrNull { it.optInt("id", -1) == routineId }
            val views = RemoteViews(context.packageName, R.layout.routine_widget)
            val title = routine?.optString("title") ?: context.getString(R.string.routine_widget_name)
            var status = context.getString(R.string.routine_widget_unavailable)
            var symbol = "—"
            val running = routine?.optBoolean("running") == true
            views.setViewVisibility(R.id.routine_clock, View.GONE)
            views.setViewVisibility(R.id.routine_progress, View.VISIBLE)
            if (routine != null && routine.optBoolean("available")) {
                when (routine.optString("type")) {
                    "CHECKBOX" -> {
                        val done = routine.optBoolean("done")
                        symbol = if (done) "☑" else "☐"
                        status = context.getString(if (done) R.string.routine_widget_undo else R.string.routine_widget_complete)
                    }
                    "COUNTER" -> {
                        symbol = "+1"
                        status = "${routine.optInt("count")}/${routine.optInt("target") }"
                    }
                    "TIMER" -> {
                        symbol = if (running) "Ⅱ" else "▶"
                        val startedAt = routine.optLong("startedAt", 0)
                        val seconds = if (running && startedAt > 0) {
                            routine.optLong("startSeconds") + (System.currentTimeMillis() - startedAt).coerceAtLeast(0) / 1000
                        } else routine.optLong("seconds")
                        views.setChronometer(R.id.routine_clock,
                            SystemClock.elapsedRealtime() - seconds * 1000, null, running)
                        views.setViewVisibility(R.id.routine_clock, View.VISIBLE)
                        views.setViewVisibility(R.id.routine_progress, View.GONE)
                        status = context.getString(if (running) R.string.routine_widget_pause else R.string.routine_widget_start)
                    }
                }
            }
            var error = prefs.getString("routineWidgetError_$routineId", null)
            if (error == "permission") {
                val notificationsGranted = Build.VERSION.SDK_INT < 33 ||
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                val alarmsGranted = Build.VERSION.SDK_INT < 31 ||
                    (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()
                if (notificationsGranted && alarmsGranted) {
                    prefs.edit().remove("routineWidgetError_$routineId").apply()
                    error = null
                }
            }
            if (error != null) {
                status = context.getString(if (error == "permission") R.string.routine_widget_permission else R.string.routine_widget_error)
                views.setViewVisibility(R.id.routine_clock, View.GONE)
                views.setViewVisibility(R.id.routine_progress, View.VISIBLE)
            }
            views.setTextViewText(R.id.routine_title, title)
            views.setTextViewText(R.id.routine_action, symbol)
            views.setTextViewText(R.id.routine_progress, status)
            views.setContentDescription(R.id.routine_button, "$title, $status")
            val click = if (routine == null || error == "permission") {
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            } else {
                HomeWidgetBackgroundIntent.getBroadcast(context,
                    Uri.parse("nextlevel://routine?action=routine_toggle&routineId=$routineId"))
            }
            views.setOnClickPendingIntent(R.id.routine_button, click)
            AppWidgetManager.getInstance(context).updateAppWidget(id, views)
        }
    }
}
