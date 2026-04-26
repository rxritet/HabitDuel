import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionHeader(title: 'Напоминания'),
                SwitchListTile(
                  title: const Text('Ежедневное напоминание'),
                  subtitle: const Text('Напоминать о check-in'),
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                ),
                ListTile(
                  title: const Text('Время напоминания'),
                  subtitle: Text(_reminderTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  enabled: _reminderEnabled,
                  onTap: _reminderEnabled ? _pickTime : null,
                ),
                const Divider(height: 32),
                const _SectionHeader(title: 'Оформление'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Система'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Светлая'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Темная'),
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
                const _SectionHeader(title: 'Аккаунт'),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выйти',
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
