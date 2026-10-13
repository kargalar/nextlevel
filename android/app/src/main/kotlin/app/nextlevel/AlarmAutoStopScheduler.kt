package app.nextlevel

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Schedules native alarm stop commands so the timeout also works in background. */
object AlarmAutoStopScheduler {
    private const val PREFERENCES_NAME = "alarm_auto_stop_scheduler"
    private const val IDS_KEY = "scheduled_ids"

    fun schedule(context: Context, id: Int, stopAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = createPendingIntent(context, id)

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                try {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        stopAtMillis,
                        pendingIntent,
                    )
                } catch (_: SecurityException) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        stopAtMillis,
                        pendingIntent,
                    )
                }
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, stopAtMillis, pendingIntent)
            }
            else -> alarmManager.set(AlarmManager.RTC_WAKEUP, stopAtMillis, pendingIntent)
        }

        updateScheduledIds(context) { ids -> ids.add(id) }
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(createPendingIntent(context, id))
        updateScheduledIds(context) { ids -> ids.remove(id) }
    }

    fun cancelAll(context: Context) {
        val ids = getScheduledIds(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        ids.forEach { id -> alarmManager.cancel(createPendingIntent(context, id)) }
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(IDS_KEY)
            .apply()
    }

    private fun createPendingIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, AlarmAutoStopReceiver::class.java).apply {
            putExtra(AlarmAutoStopReceiver.EXTRA_ALARM_ID, id)
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
    }

    private fun immutableFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }

    private fun getScheduledIds(context: Context): MutableSet<Int> {
        return context
            .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .getStringSet(IDS_KEY, emptySet())
            ?.mapNotNull { it.toIntOrNull() }
            ?.toMutableSet()
            ?: mutableSetOf()
    }

    private fun updateScheduledIds(context: Context, update: (MutableSet<Int>) -> Unit) {
        val ids = getScheduledIds(context)
        update(ids)
        context
            .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(IDS_KEY, ids.map(Int::toString).toSet())
            .apply()
    }
}
