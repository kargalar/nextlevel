package app.nextlevel

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class StreakWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, it) }
    }

    companion object {
        fun update(context: Context, id: Int) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)
            val data = try {
                JSONObject(HomeWidgetPlugin.getData(context)
                    .getString("streakWidgetData", "{}"))
            } catch (_: Exception) { JSONObject() }
            val streak = data.optInt("currentStreak", 0)
            val todaySeconds = data.optLong("todaySeconds", 0).coerceAtLeast(0)
            val targetSeconds = data.optLong(
                "targetSeconds",
                data.optInt("targetMinutes", 0).toLong() * 60,
            ).coerceAtLeast(0)
            val todayRunning = data.optBoolean("todayRunning", false)
            val freeze = data.optInt("freezeCount", 0)
            views.setTextViewText(R.id.streak_label,
                context.getString(R.string.streak_widget_label))
            views.setTextViewText(R.id.streak_count, streak.toString())
            val targetLabel = context.getString(
                R.string.streak_widget_minutes,
                (targetSeconds / 60).toInt(),
            )
            if (todayRunning) {
                views.setChronometer(
                    R.id.streak_status,
                    SystemClock.elapsedRealtime() - todaySeconds * 1000,
                    "%s / $targetLabel",
                    true,
                )
            } else {
                views.setTextViewText(
                    R.id.streak_status,
                    context.getString(
                        R.string.streak_widget_today,
                        (todaySeconds / 60).toInt(),
                        (targetSeconds / 60).toInt(),
                    ),
                )
            }
            views.setTextViewText(R.id.streak_freeze,
                context.getString(R.string.streak_widget_freeze, freeze))
            views.setViewVisibility(R.id.streak_freeze, if (freeze > 0) View.VISIBLE else View.GONE)
            views.setOnClickPendingIntent(R.id.streak_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            AppWidgetManager.getInstance(context).updateAppWidget(id, views)
        }
    }
}
