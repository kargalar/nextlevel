package app.nextlevel

import android.content.Intent
import android.app.Notification
import android.app.NotificationManager
import android.os.Bundle
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterActivity() {
	private companion object {
		const val ANDROID_API_LEVEL_LIVE_UPDATES = 36
	}

	private val timezoneChannel = "app.nextlevel/timezone"
	private val alarmAutoStopChannel = "app.nextlevel/alarm_auto_stop"
	private val voiceShortcutChannel = "app.nextlevel/voice_shortcut"
	private val liveUpdateChannel = "app.nextlevel/live_updates"
	private val voiceShortcutAction = "app.nextlevel.action.VOICE_TASK"
	private var initialVoiceShortcut = false
	private var pendingVoiceShortcut = false
	private var voiceChannel: MethodChannel? = null

	override fun onCreate(savedInstanceState: android.os.Bundle?) {
		initialVoiceShortcut = isVoiceShortcutIntent(intent)
		if (initialVoiceShortcut) {
			setTheme(R.style.VoiceShortcutTheme)
		}
		super.onCreate(savedInstanceState)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.nextlevel/routine_widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "pin") {
                    val routineId = call.arguments as? Int
                    if (routineId == null || routineId < 0) {
                        result.error("INVALID_ROUTINE", "Invalid routine ID", null)
                    } else {
                        result.success(RoutineWidgetProvider.pin(this, routineId))
                    }
                } else result.notImplemented()
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.nextlevel/task_template_widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "pin") {
                    val templateId = call.arguments as? Int
                    if (templateId == null || templateId < 0) {
                        result.error("INVALID_TEMPLATE", "Invalid task template ID", null)
                    } else {
                        result.success(TaskTemplateWidgetProvider.pin(this, templateId))
                    }
                } else result.notImplemented()
            }

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timezoneChannel).setMethodCallHandler { call, result ->
			when (call.method) {
				"getLocalTimezone" -> {
					try {
						// Try to provide an IANA-like ID where possible
						val tz: String = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
							// getID returns an Olson/IANA TZ on Android (e.g., Europe/Istanbul)
							TimeZone.getDefault().id
						} else {
							TimeZone.getDefault().id
						}
						result.success(tz)
					} catch (e: Exception) {
						result.error("TZ_ERROR", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, liveUpdateChannel).setMethodCallHandler { call, result ->
			if (call.method != "promoteOngoingNotification") {
				result.notImplemented()
				return@setMethodCallHandler
			}

			if (Build.VERSION.SDK_INT < ANDROID_API_LEVEL_LIVE_UPDATES) {
				result.success(false)
				return@setMethodCallHandler
			}

			val notificationId = call.argument<Int>("id")
			if (notificationId == null) {
				result.error("INVALID_NOTIFICATION_ID", "Notification ID is required", null)
				return@setMethodCallHandler
			}

			try {
				val notificationManager = getSystemService(NotificationManager::class.java)
				if (!notificationManager.canPostPromotedNotifications()) {
					result.success(false)
					return@setMethodCallHandler
				}

				val activeNotification = notificationManager.activeNotifications
					.firstOrNull { it.id == notificationId }
				if (activeNotification == null) {
					result.success(false)
					return@setMethodCallHandler
				}

				val promotedNotification = Notification.Builder
					.recoverBuilder(this, activeNotification.notification)
					.addExtras(Bundle().apply {
						putBoolean("android.requestPromotedOngoing", true)
					})
					.build()

				notificationManager.notify(
					activeNotification.tag,
					activeNotification.id,
					promotedNotification,
				)
				result.success(true)
			} catch (error: Exception) {
				result.error("LIVE_UPDATE_ERROR", error.message, null)
			}
		}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmAutoStopChannel).setMethodCallHandler { call, result ->
			try {
				when (call.method) {
					"scheduleAutoStop" -> {
						val id = requireNotNull(call.argument<Int>("id"))
						val stopAtMillis = requireNotNull(call.argument<Long>("stopAtMillis"))
						AlarmAutoStopScheduler.schedule(this, id, stopAtMillis)
						result.success(null)
					}
					"cancelAutoStop" -> {
						val id = requireNotNull(call.argument<Int>("id"))
						AlarmAutoStopScheduler.cancel(this, id)
						result.success(null)
					}
					"cancelAllAutoStops" -> {
						AlarmAutoStopScheduler.cancelAll(this)
						result.success(null)
					}
					else -> result.notImplemented()
				}
			} catch (error: Exception) {
				result.error("ALARM_AUTO_STOP_ERROR", error.message, null)
			}
		}

		voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, voiceShortcutChannel)
		voiceChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"getInitialShortcut" -> {
					val isShortcut = initialVoiceShortcut
					initialVoiceShortcut = false
					result.success(isShortcut)
				}
				"finishShortcut" -> {
					finish()
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}

		if (pendingVoiceShortcut) {
			pendingVoiceShortcut = false
			voiceChannel?.invokeMethod("voiceTaskShortcut", null)
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		if (!isVoiceShortcutIntent(intent)) return

		if (voiceChannel == null) {
			pendingVoiceShortcut = true
		} else {
			voiceChannel?.invokeMethod("voiceTaskShortcut", null)
		}
	}

	private fun isVoiceShortcutIntent(intent: Intent?): Boolean {
		return intent?.action == voiceShortcutAction
	}
}
