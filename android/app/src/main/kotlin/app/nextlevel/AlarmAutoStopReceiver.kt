package app.nextlevel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.gdelataillade.alarm.alarm.AlarmReceiver

/** Sends the alarm package's native stop action when the timeout is reached. */
class AlarmAutoStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ALARM_ID, 0)
        if (id == 0) return

        AlarmAutoStopScheduler.cancel(context, id)

        val stopIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_STOP
            putExtra("id", id)
        }
        context.sendBroadcast(stopIntent)
    }

    companion object {
        const val EXTRA_ALARM_ID = "alarm_id"
    }
}
