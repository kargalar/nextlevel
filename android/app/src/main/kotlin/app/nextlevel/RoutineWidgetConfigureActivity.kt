package app.nextlevel

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

class RoutineWidgetConfigureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        if (id < 0) { finish(); return }
        val routines = RoutineWidgetProvider.routines(this)
        val dialog = AlertDialog.Builder(this).setTitle(R.string.routine_widget_choose)
            .setOnCancelListener { finish() }
        if (routines.isEmpty()) {
            dialog.setMessage(R.string.routine_widget_empty)
                .setPositiveButton(android.R.string.ok) { _, _ -> finish() }
        } else {
            dialog.setItems(routines.map { it.optString("title") }.toTypedArray()) { _, index ->
                RoutineWidgetProvider.configure(this, id, routines[index].getInt("id"))
                setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))
                finish()
            }
        }
        dialog.show()
    }
}
