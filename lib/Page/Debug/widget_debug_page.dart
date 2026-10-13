import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Debug/vacation_dates_list_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/widget_debug_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/logging_service.dart';

class WidgetDebugPage extends StatefulWidget {
  const WidgetDebugPage({super.key});

  @override
  State<WidgetDebugPage> createState() => _WidgetDebugPageState();
}

class _WidgetDebugPageState extends State<WidgetDebugPage> {
  String _lastAction = 'No action performed yet';
  bool _isLoading = false;

  Future<void> _performAction(String actionName, Future<void> Function() action) async {
    if (!kDebugMode) return;

    setState(() {
      _isLoading = true;
      _lastAction = 'Performing: $actionName...';
    });

    try {
      await action();
      setState(() {
        _lastAction = 'Done: $actionName ✅';
      });
    } catch (e) {
      setState(() {
        _lastAction = 'Failed: $actionName ❌ - $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug')),
        body: const Center(
          child: Text('Debug page only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Debug'),
        backgroundColor: AppColors.main,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Status Card
            Card(
              color: AppColors.panelBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Action:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastAction,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notification Test Actions
            Text(
              'Notification Test Actions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 16),

            // Instant Notification Test
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Instant Notification Test',
                        () async {
                          await NotificationService.flutterLocalNotificationsPlugin.show(
                            999991,
                            '📢 Anında Bildirim Testi',
                            'Bu bir anında bildirim testidir. Şu an: ${DateTime.now().toString().split('.')[0]}',
                            NotificationService().notificationDetails(false),
                          );
                          LogService.debug('✅ Anında bildirim gönderildi');
                        },
                      ),
              icon: const Icon(Icons.notifications_active),
              label: const Text('Anında Bildirim Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Scheduled Notification Test (5 seconds)
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Scheduled Notification Test',
                        () async {
                          final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
                          await NotificationService().scheduleNotification(
                            id: 999992,
                            title: '⏰ Zamanlanmış Bildirim Testi',
                            desc: 'Bu bildirim 5 saniye sonra gösterildi!',
                            scheduledDate: scheduledTime,
                            isAlarm: false,
                          );
                          LogService.debug('✅ 5 saniye sonrası için bildirim zamanlandı: $scheduledTime');
                        },
                      ),
              icon: const Icon(Icons.schedule),
              label: const Text('Zamanlanmış Bildirim (5sn)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Alarm Test (10 seconds)
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Alarm Test',
                        () async {
                          final alarmTime = DateTime.now();
                          await NotificationService().scheduleNotification(
                            id: 999993,
                            title: '🚨 Alarm Testi',
                            desc: 'Bu bir alarm testidir!.',
                            scheduledDate: alarmTime,
                            isAlarm: true,
                          );
                          LogService.debug('✅ Alarm : $alarmTime');
                        },
                      ),
              icon: const Icon(Icons.alarm),
              label: const Text('Alarm Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // All Notification Tests (Combined)
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'All Notification Tests',
                        () async => NotificationService().notificationTest(),
                      ),
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Tüm Bildirim Testleri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Widget Debug Actions
            Text(
              'Widget Debug Actions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 16),

            // Debug Widget Data
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Debug Widget Data',
                        () async => WidgetDebugService.debugWidgetData(),
                      ),
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Widget Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Force Widget Update
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Force Widget Update',
                        () async => WidgetDebugService.forceWidgetUpdate(),
                      ),
              icon: const Icon(Icons.refresh),
              label: const Text('Force Widget Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Create Test Tasks
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Create Test Tasks',
                        () async => WidgetDebugService.createTestTasksForWidget(),
                      ),
              icon: const Icon(Icons.add_task),
              label: const Text('Create Test Tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightMain,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Test Widget with Sample Data
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Test Widget with Sample Data',
                        () async => WidgetDebugService.testWidgetWithSampleData(),
                      ),
              icon: const Icon(Icons.science),
              label: const Text('Test Widget with Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dirtyMain,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Remove Test Tasks
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Remove Test Tasks',
                        () async => WidgetDebugService.removeTestTasksForWidget(),
                      ),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Remove Test Tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // View Vacation Dates
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      NavigatorService().goTo(const VacationDatesListPage());
                    },
              icon: const Icon(Icons.beach_access),
              label: const Text('View Vacation Dates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Reset Widget
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _performAction(
                        'Reset Widget',
                        () async => HomeWidgetService.resetHomeWidget(),
                      ),
              icon: const Icon(Icons.restore),
              label: const Text('Reset Widget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: AppColors.panelBackground2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Instructions:\n\n'
                  'Notification Tests:\n'
                  '• Anında Bildirim: Hemen görünür\n'
                  '• Zamanlanmış Bildirim: 5 saniye sonra\n'
                  '• Alarm Test: 10 saniye sonra çalar\n'
                  '• Tüm Testler: Hepsini sırayla dener\n\n'
                  'Widget Tests:\n'
                  '1. Check debug console for detailed logs\n'
                  '2. Add widget to home screen first\n'
                  '3. Use "Test Widget with Sample Data" for quick test\n'
                  '4. Check widget on home screen after each action',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
