package app.nextlevel

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

class TaskTemplateWidgetConfigureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        if (id < 0) {
            finish()
            return
        }

        val templates = TaskTemplateWidgetProvider.templates(this)
        val dialog = AlertDialog.Builder(this)
            .setTitle(R.string.task_template_widget_choose)
            .setOnCancelListener { finish() }
        if (templates.isEmpty()) {
            dialog.setMessage(R.string.task_template_widget_empty)
                .setPositiveButton(android.R.string.ok) { _, _ -> finish() }
        } else {
            dialog.setItems(templates.map { it.optString("title") }.toTypedArray()) { _, index ->
                TaskTemplateWidgetProvider.configure(
                    this,
                    id,
                    templates[index].getInt("id"),
                )
                setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))
                finish()
            }
        }
        dialog.show()
    }
}
