import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool(kReminderEnabledKey) ?? false;
      _reminderTime = TimeOfDay(
        hour: prefs.getInt(kReminderHourKey) ?? 9,
        minute: prefs.getInt(kReminderMinuteKey) ?? 0,
      );
      _loading = false;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _reminderEnabled = value);
    await NotificationService.instance.saveAndScheduleReminder(
      enabled: value,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    if (_reminderEnabled) {
      await NotificationService.instance.saveAndScheduleReminder(
        enabled: true,
        hour: picked.hour,
        minute: picked.minute,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kReminderHourKey, picked.hour);
      await prefs.setInt(kReminderMinuteKey, picked.minute);
    }
  }

  Future<void> _checkUpdatesManually() async {
    final result =
        await ref.read(appUpdateServiceProvider).checkForUpdate(manual: true);
    if (!mounted) return;

    if (!result.updateAvailable || result.remote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас уже установлена актуальная версия')),
      );
      return;
    }

    await showAppUpdateDialog(
      context,
      result: result,
      onDownload: () async {
        final opened = await ref.read(appUpdateServiceProvider).openDownload(
              result.remote!,
            );
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть ссылку на APK')),
          );
        }
      },
      onLater: () => ref
          .read(appUpdateServiceProvider)
          .dismissVersion(result.remote!.versionCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionHeader(title: 'Daily Reminder'),
                SwitchListTile(
                  title: const Text('Enable daily reminder'),
                  subtitle: const Text('Напоминание о check-in'),
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                ),
                ListTile(
                  title: const Text('Reminder time'),
                  subtitle: Text(_reminderTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  enabled: _reminderEnabled,
                  onTap: _reminderEnabled ? _pickTime : null,
                ),
                const Divider(height: 32),
                const _SectionHeader(title: 'Appearance'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(selection.first),
                  ),
                ),
                const Divider(height: 32),
                const _SectionHeader(title: 'Updates'),
                ListTile(
                  leading: const Icon(Icons.system_update_alt_outlined),
                  title: const Text('Check for updates'),
                  subtitle: const Text('Проверить новую APK-версию через Firebase'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _checkUpdatesManually,
                ),
                const Divider(height: 32),
                const _SectionHeader(title: 'Account'),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
