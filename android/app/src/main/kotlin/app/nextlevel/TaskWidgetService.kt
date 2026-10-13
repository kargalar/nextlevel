package app.nextlevel

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        android.util.Log.d("TaskWidgetService", "=== onGetViewFactory called ===")
        return TaskViewsFactory(applicationContext)
    }

    class TaskViewsFactory(private val context: Context) : RemoteViewsFactory {
        private data class TaskDetail(
            val id: Int,
            val title: String,
            val type: String,
            val section: String = "TASKS",
            val status: String = "",
            val currentCount: Int = 0,
            val targetCount: Int = 0,
            val currentDurationSec: Int = 0,
            val targetDurationSec: Int = 0,
            val isTimerActive: Boolean = false,
            val notificationTime: String? = null
        )

        private sealed class ListItem {
            data class Header(val title: String) : ListItem()
            data class Task(val detail: TaskDetail) : ListItem()
        }

        private var tasks: List<TaskDetail> = emptyList()
        private var listItems: List<ListItem> = emptyList()

        override fun onCreate() {
            // android.util.Log.d("TaskWidgetService", "onCreate called")
        }

        override fun onDataSetChanged() {
            // android.util.Log.d("TaskWidgetService", "=== onDataSetChanged ===")
            try {
                val data = HomeWidgetPlugin.getData(context)
                val detailsJson = data.getString("taskDetails", "[]")
                val arr = JSONArray(detailsJson)
                val list = ArrayList<TaskDetail>(arr.length())
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    list.add(
                        TaskDetail(
                            id = o.optInt("id"),
                            title = o.optString("title"),
                            type = o.optString("type"),
                            section = o.optString("section", "TASKS"),
                            status = o.optString("status", ""),
                            currentCount = o.optInt("currentCount"),
                            targetCount = o.optInt("targetCount"),
                            currentDurationSec = o.optInt("currentDurationSec"),
                            targetDurationSec = o.optInt("targetDurationSec"),
                            isTimerActive = o.optBoolean("isTimerActive"),
                            notificationTime = if (o.isNull("notificationTime")) null else o.optString("notificationTime")
                        )
                    )
                }
                tasks = list

                // Build list items with section headers
                val items = mutableListOf<ListItem>()
                var currentSection: String? = null

                for (task in tasks) {
                    if (task.section != currentSection) {
                        val headerTitle = when (task.section) {
                            "OVERDUE" -> "⚠️ OVERDUE"
                            "PINNED" -> "📌 PINNED"
                            "TASKS" -> "📋 TASKS"
                            "ROUTINES" -> "🔄 ROUTINES"
                            else -> task.section
                        }
                        items.add(ListItem.Header(headerTitle))
                        currentSection = task.section
                    }
                    items.add(ListItem.Task(task))
                }

                listItems = items
                android.util.Log.d("TaskWidgetService", "Tasks: ${tasks.size}, Items: ${listItems.size}")
            } catch (e: Exception) {
                android.util.Log.e("TaskWidgetService", "Error parsing task details", e)
            }
        }

        override fun onDestroy() {
            tasks = emptyList()
            listItems = emptyList()
        }

        override fun getCount(): Int = listItems.size

        override fun getViewAt(position: Int): RemoteViews? {
            if (position < 0 || position >= listItems.size) return null

            return when (val listItem = listItems[position]) {
                is ListItem.Header -> {
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_section_header)
                    rv.setTextViewText(R.id.section_header_title, listItem.title)
                    rv
                }
                is ListItem.Task -> {
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
                    val item = listItem.detail

                    rv.setOnClickFillInIntent(
                        R.id.task_item_root,
                        Intent().apply {
                            data = Uri.parse(
                                "nextlevel://task-widget?action=task_toggle&taskId=${item.id}"
                            )
                        },
                    )

                    // Set title
                    rv.setTextViewText(R.id.task_item_title, item.title)

                    // Title color based on status
                    val isDone = item.status == "DONE"
                    val isFailed = item.status == "FAILED"
                    val actionIcon = when (item.type) {
                        "CHECKBOX" -> if (isDone) "☑" else "☐"
                        "COUNTER" -> "+"
                        "TIMER" -> if (item.isTimerActive) "⏸" else "▶"
                        else -> "•"
                    }
                    val actionColor = when {
                        isFailed -> 0xFFEF5350.toInt()
                        item.type == "TIMER" && item.isTimerActive -> 0xFFFFB74D.toInt()
                        item.type == "COUNTER" -> 0xFF81C784.toInt()
                        else -> 0xFF90CAF9.toInt()
                    }
                    rv.setTextViewText(R.id.task_item_action, actionIcon)
                    rv.setTextColor(R.id.task_item_action, actionColor)
                    rv.setContentDescription(R.id.task_item_root, "$actionIcon ${item.title}")
                    when {
                        isDone -> rv.setTextColor(R.id.task_item_title, 0xFF555555.toInt())
                        isFailed -> rv.setTextColor(R.id.task_item_title, 0xFF664444.toInt())
                        item.section == "OVERDUE" -> rv.setTextColor(R.id.task_item_title, 0xFFCC8844.toInt())
                        else -> rv.setTextColor(R.id.task_item_title, 0xFFE0E0E0.toInt())
                    }

                    // Status badge (Done / Fail) for checkbox tasks
                    if (isDone) {
                        rv.setTextViewText(R.id.task_item_status_badge, "Done")
                        rv.setInt(R.id.task_item_status_badge, "setBackgroundResource", R.drawable.badge_active_bg)
                        rv.setTextColor(R.id.task_item_status_badge, 0xFF64B5F6.toInt())
                        rv.setViewVisibility(R.id.task_item_status_badge, View.VISIBLE)
                    } else if (isFailed) {
                        rv.setTextViewText(R.id.task_item_status_badge, "Fail")
                        rv.setInt(R.id.task_item_status_badge, "setBackgroundResource", R.drawable.badge_fail_bg)
                        rv.setTextColor(R.id.task_item_status_badge, 0xFFEF5350.toInt())
                        rv.setViewVisibility(R.id.task_item_status_badge, View.VISIBLE)
                    } else {
                        rv.setViewVisibility(R.id.task_item_status_badge, View.GONE)
                    }

                    // Notification time display
                    if (item.notificationTime != null) {
                        rv.setTextViewText(R.id.task_item_notification_time, "🔔 ${item.notificationTime}")
                        rv.setViewVisibility(R.id.task_item_notification_time, View.VISIBLE)
                    } else {
                        rv.setViewVisibility(R.id.task_item_notification_time, View.GONE)
                    }

                    // Progress subtitle for counter/timer tasks
                    var sub = ""
                    when (item.type) {
                        "COUNTER" -> {
                            val tgt = if (item.targetCount > 0) item.targetCount else 1
                            sub = "${item.currentCount}/$tgt"
                        }
                        "TIMER" -> {
                            fun formatDuration(totalSec: Int): String {
                                val h = totalSec / 3600
                                val m = (totalSec % 3600) / 60
                                return if (h > 0) "${h}sa ${m}dk" else "${m}dk"
                            }
                            sub = "${formatDuration(item.currentDurationSec)} / ${formatDuration(item.targetDurationSec)}"
                        }
                    }
                    if (sub.isNotEmpty()) {
                        rv.setTextViewText(R.id.task_item_sub, sub)
                        rv.setViewVisibility(R.id.task_item_sub, View.VISIBLE)
                    } else {
                        rv.setViewVisibility(R.id.task_item_sub, View.GONE)
                    }

                    rv
                }
            }
        }

        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount(): Int = 2
        override fun getItemId(position: Int): Long = position.toLong()
        override fun hasStableIds(): Boolean = true
    }
}
