import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/backup_scheduler_service.dart';
import 'package:next_level/Service/backup_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveBackupPage extends StatefulWidget {
  const GoogleDriveBackupPage({super.key});

  @override
  State<GoogleDriveBackupPage> createState() => _GoogleDriveBackupPageState();
}

class _GoogleDriveBackupPageState extends State<GoogleDriveBackupPage> {
  final BackupService _backupService = BackupService();
  final BackupSchedulerService _scheduler = BackupSchedulerService();

  bool _isLoading = true;
  bool _isAutoBackupEnabled = false;
  bool _isWifiOnly = true;
  BackupFrequency _backupFrequency = BackupFrequency.daily;
  List<DriveBackupInfo> _backups = const [];
  DateTime? _lastAutoBackupAttempt;
  String? _lastAutoBackupError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoBackupEnabled =
        prefs.getBool(BackupSchedulerService.enabledPreference) ?? false;
    _isWifiOnly =
        prefs.getBool(BackupSchedulerService.wifiOnlyPreference) ?? true;
    _backupFrequency = BackupFrequency.fromPreference(
      prefs.getString(BackupSchedulerService.frequencyPreference),
    );
    _lastAutoBackupAttempt = DateTime.tryParse(
      prefs.getString(BackupSchedulerService.lastAttemptPreference) ?? '',
    );
    _lastAutoBackupError =
        prefs.getString(BackupSchedulerService.lastErrorPreference);

    await _backupService.initialize();
    if (_backupService.currentUser != null) {
      _backups = await _backupService.listBackups();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _reloadBackups() async {
    final backups = await _backupService.listBackups();
    final prefs = await SharedPreferences.getInstance();
    final lastAttempt = DateTime.tryParse(
      prefs.getString(BackupSchedulerService.lastAttemptPreference) ?? '',
    );
    final lastError =
        prefs.getString(BackupSchedulerService.lastErrorPreference);
    if (mounted) {
      setState(() {
        _backups = backups;
        _lastAutoBackupAttempt = lastAttempt;
        _lastAutoBackupError = lastError;
      });
    }
  }

  Future<void> _signIn() async {
    final wasConnected = _backupService.currentUser != null;
    setState(() => _isLoading = true);
    final user = await _backupService.signIn();
    if (user != null) {
      await _reloadBackups();
      if (mounted) setState(() => _isLoading = false);
      _showMessage(
        'Connected as ${user.email}',
        status: StatusEnum.SUCCESS,
      );
      if (!wasConnected && _backups.isNotEmpty && mounted) {
        await _restoreBackup(_backups.first, offeredAfterConnection: true);
      }
    } else {
      _showMessage(
        _backupService.lastError ?? 'Google sign-in was cancelled or failed.',
        status: StatusEnum.ERROR,
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await _scheduler.configure(
        enabled: false,
        wifiOnly: _isWifiOnly,
        frequency: _backupFrequency,
      );
      await _backupService.signOut();
      if (mounted) {
        setState(() {
          _isAutoBackupEnabled = false;
          _backups = const [];
        });
      }
      _showMessage('Google Drive disconnected.', status: StatusEnum.INFO);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _manualBackup() async {
    setState(() => _isLoading = true);
    final result = await _backupService.backupData(wifiOnly: _isWifiOnly);
    if (result.isSuccess) {
      await _reloadBackups();
      _showMessage('Backup uploaded successfully.');
    } else {
      _showOperationError(result);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _restoreBackup(
    DriveBackupInfo backup, {
    bool offeredAfterConnection = false,
  }) async {
    final backupTime = backup.modifiedTime == null
        ? 'the selected backup'
        : DateFormat('dd MMM yyyy, HH:mm')
            .format(backup.modifiedTime!.toLocal());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          offeredAfterConnection
              ? 'Existing backup found'
              : 'Restore Google Drive backup?',
        ),
        content: Text(
          '${offeredAfterConnection ? 'A backup from $backupTime is already available in Google Drive. Restore it now? ' : ''}'
          'This will replace all local tasks, routines, progress, settings and '
          'attachments with the backup from $backupTime. A local safety copy '
          'will be used automatically if restoration fails.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(offeredAfterConnection ? 'Not now' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore',
              style: TextStyle(color: AppColors.dirtyRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final result = await _backupService.restoreData(backup: backup);
    if (result.isSuccess) {
      _showMessage(
        'Backup restored successfully. Reopen the app to apply every setting.',
        duration: const Duration(seconds: 5),
      );
    } else {
      _showOperationError(result);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteBackup(DriveBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete backup?'),
        content: const Text(
          'This permanently deletes this snapshot from the private app data '
          'area in Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.dirtyRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final result = await _backupService.deleteBackup(backup);
    if (result.isSuccess) {
      await _reloadBackups();
      _showMessage('Backup deleted.', status: StatusEnum.INFO);
    } else {
      _showOperationError(result);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _setAutoBackup(bool enabled) async {
    if (enabled && _backupService.currentUser == null) {
      _showMessage(
        'Connect Google Drive before enabling automatic backup.',
        status: StatusEnum.ERROR,
      );
      return;
    }

    final previous = _isAutoBackupEnabled;
    setState(() => _isAutoBackupEnabled = enabled);
    try {
      await _scheduler.configure(
        enabled: enabled,
        wifiOnly: _isWifiOnly,
        frequency: _backupFrequency,
      );
    } catch (error) {
      if (mounted) setState(() => _isAutoBackupEnabled = previous);
      _showMessage(
        'Automatic backup could not be scheduled: $error',
        status: StatusEnum.ERROR,
      );
    }
  }

  Future<void> _setWifiOnly(bool wifiOnly) async {
    final previous = _isWifiOnly;
    setState(() => _isWifiOnly = wifiOnly);
    try {
      await _scheduler.configure(
        enabled: _isAutoBackupEnabled,
        wifiOnly: wifiOnly,
        frequency: _backupFrequency,
      );
    } catch (error) {
      if (mounted) setState(() => _isWifiOnly = previous);
      _showMessage(
        'Backup network preference could not be saved: $error',
        status: StatusEnum.ERROR,
      );
    }
  }

  Future<void> _setBackupFrequency(BackupFrequency frequency) async {
    final previous = _backupFrequency;
    setState(() => _backupFrequency = frequency);
    try {
      await _scheduler.configure(
        enabled: _isAutoBackupEnabled,
        wifiOnly: _isWifiOnly,
        frequency: frequency,
      );
    } catch (error) {
      if (mounted) setState(() => _backupFrequency = previous);
      _showMessage(
        'Backup frequency could not be saved: $error',
        status: StatusEnum.ERROR,
      );
    }
  }

  void _showOperationError(BackupOperationResult result) {
    final detail = result.error?.toString();
    final message = result.message ??
        (detail == null
            ? 'The operation failed.'
            : 'The operation failed: $detail');
    _showMessage(message, status: StatusEnum.ERROR);
  }

  void _showMessage(
    String message, {
    StatusEnum status = StatusEnum.SUCCESS,
    Duration? duration,
  }) {
    if (!mounted) return;
    Helper().getMessage(
      message: message,
      status: status,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: NavigatorService().back,
          child: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoading
          ? const _LoadingIndicator()
          : !BackupService.isSupported
              ? const _UnsupportedMessage()
              : RefreshIndicator(
                  onRefresh: _reloadBackups,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_backupService.currentUser == null)
                        _buildDisconnectedState()
                      else
                        _buildConnectedState(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDisconnectedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.add_to_drive_rounded, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Connect Google Drive to keep private, restorable snapshots of all '
          'app data and task attachments. Backups are stored in the hidden '
          'application-data area and are not shared with other apps.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _signIn,
          icon: const Icon(Icons.link_rounded),
          label: const Text('Connect Google Drive'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.main,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(_backupService.currentUser!.email),
          subtitle: const Text('Private Drive app data connected'),
          trailing: TextButton(
            onPressed: _signOut,
            child: const Text(
              'Disconnect',
              style: TextStyle(color: AppColors.dirtyRed),
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _manualBackup,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Back Up Now'),
        ),
        if (_backupService.lastError != null) ...[
          const SizedBox(height: 12),
          Text(
            _backupService.lastError!,
            style: const TextStyle(color: AppColors.dirtyRed),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Backup History (${_backups.length}/${BackupService.retainedBackupCount})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_backups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No backup was found. Create the first snapshot with “Back Up Now”.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._backups.asMap().entries.map(
                (entry) => _buildBackupTile(
                  entry.value,
                  isLatest: entry.key == 0,
                ),
              ),
        if (BackupSchedulerService.isSupported) ...[
          const SizedBox(height: 28),
          const Text(
            'Automatic Backup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Automatic backup'),
            subtitle: Text(
              'The operating system runs this '
              '${_backupFrequency.scheduleDescription}.',
            ),
            value: _isAutoBackupEnabled,
            onChanged: _setAutoBackup,
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<BackupFrequency>(
            initialValue: _backupFrequency,
            decoration: const InputDecoration(
              labelText: 'Backup frequency',
              prefixIcon: Icon(Icons.schedule_rounded),
              border: OutlineInputBorder(),
            ),
            items: BackupFrequency.values
                .map(
                  (frequency) => DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (frequency) {
              if (frequency != null) _setBackupFrequency(frequency);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wi-Fi only'),
            subtitle: const Text('Avoid mobile-data uploads.'),
            value: _isWifiOnly,
            onChanged: _setWifiOnly,
          ),
          if (_lastAutoBackupAttempt != null)
            Text(
              'Last automatic attempt: ${DateFormat('dd MMM yyyy, HH:mm').format(_lastAutoBackupAttempt!.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_lastAutoBackupError != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last automatic backup: $_lastAutoBackupError',
              style: const TextStyle(color: AppColors.dirtyRed),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBackupTile(DriveBackupInfo backup, {required bool isLatest}) {
    final time = backup.modifiedTime == null
        ? 'Unknown date'
        : DateFormat('dd MMM yyyy, HH:mm')
            .format(backup.modifiedTime!.toLocal());
    final details = <String>[
      if (backup.size != null) _formatBytes(backup.size!),
      if (backup.schemaVersion != null) 'format v${backup.schemaVersion}',
    ];

    return Card(
      child: ListTile(
        leading: Icon(
          isLatest ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
          color: isLatest ? AppColors.main : null,
        ),
        title: Text(isLatest ? '$time · Latest' : time),
        subtitle: details.isEmpty ? null : Text(details.join(' · ')),
        onTap: () => _restoreBackup(backup),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'restore') {
              _restoreBackup(backup);
            } else if (action == 'delete') {
              _deleteBackup(backup);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'restore',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restore_rounded),
                title: Text('Restore'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline_rounded),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    final megabytes = kilobytes / 1024;
    if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
    return '${(megabytes / 1024).toStringAsFixed(1)} GB';
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppColors.text),
      ),
    );
  }
}

class _UnsupportedMessage extends StatelessWidget {
  const _UnsupportedMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Google Drive backup is currently available on Android and iOS.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
