import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Ключи SharedPreferences.
const kReminderEnabledKey = 'reminder_enabled';
const kReminderHourKey = 'reminder_hour';
const kReminderMinuteKey = 'reminder_minute';

/// Идентификаторы канала / уведомлений.
const _dailyReminderId = 0;
const _streakBrokenId = 1;
const _channelId = 'habitduel_channel';
const _channelName = 'HabitDuel';

/// Сервис уведомлений (синглтон).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Вызывается один раз при запуске приложения.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Запрос разрешения на Android 13+
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ─── Ежедневное напоминание ─────────────────────────────────────────────────

  /// Запланировать (перезапланировать) ежедневное напоминание.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Сначала отменяем текущее напоминание.
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'HabitDuel',
      'Не забудь check-in! 🔥',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // повторяется ежедневно
    );
  }

  /// Отменить ежедневное напоминание.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Восстановить напоминание из сохранённых настроек (при запуске).
  Future<void> restoreReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kReminderEnabledKey) ?? false;
    if (!enabled) return;
    final hour = prefs.getInt(kReminderHourKey) ?? 9;
    final minute = prefs.getInt(kReminderMinuteKey) ?? 0;
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  /// Сохранить настройки и запланировать.
  Future<void> saveAndScheduleReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kReminderEnabledKey, enabled);
    await prefs.setInt(kReminderHourKey, hour);
    await prefs.setInt(kReminderMinuteKey, minute);

    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  // ─── Мгновенное уведомление «Атака!» ──────────────────────────────────

  /// Показать уведомление при прерыве серии противника.
  Future<void> showStreakBrokenNotification({
    required String opponentUsername,
    required int oldStreak,
  }) async {
    await _plugin.show(
      _streakBrokenId,
      'Атакуй! 🎯',
      '$opponentUsername потерял стрик ($oldStreak дней). Время атаковать!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
