package app.nextlevel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives DATE_CHANGED, TIME_SET, TIMEZONE_CHANGED, BOOT_COMPLETED and asks
 * the Flutter background to refresh widget data via the HomeWidget background channel.
 */
class DateChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val action = intent.action ?: return
            Log.d("DateChangeReceiver", "Received: $action")

            // Build intent to HomeWidgetBackgroundReceiver with refresh action
            val bgIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java)
            bgIntent.action = "es.antonborri.home_widget.action.BACKGROUND"
            // Put action in data uri so it's available in Dart as queryParameters
            bgIntent.data = android.net.Uri.parse("homewidget://system?action=refresh")

            context.sendBroadcast(bgIntent)
        } catch (e: Exception) {
            Log.e("DateChangeReceiver", "Error forwarding refresh", e)
        }
    }
}
