import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Доступные метрики здоровья для «Trusted Check-in».
enum HealthMetric {
  steps('steps', 'Шаги', '🚶'),
  sleepHours('sleep_hours', 'Сон (часы)', '😴'),
  activeMinutes('active_minutes', 'Активность (мин.)', '💪'),
  heartRateAvg('heart_rate_avg', 'Пульс (ср.)', '❤️'),
  waterMl('water_ml', 'Вода (мл)', '💧'),
  caloriesBurned('calories_burned', 'Калории', '🔥');

  const HealthMetric(this.key, this.label, this.emoji);
  final String key;
  final String label;
  final String emoji;
}

/// Результат чтения данных здоровья.
class HealthReadResult {
  const HealthReadResult({
    required this.metric,
    required this.value,
    required this.readAt,
    this.isPermissionDenied = false,
  });

  final HealthMetric metric;
  final double value;
  final DateTime readAt;
  final bool isPermissionDenied;
}

/// Сервис интеграции с Apple Health / Google Health Connect.
///
/// Использует заглушки на не-мобильных платформах.
/// После добавления пакета `health` в pubspec — реализует реальные запросы.
class HealthService {
  HealthService._();
  static final instance = HealthService._();

  static const _prefPrefix = 'health_perm_';

  /// Инициализация (запрос прав, если требуется).
  Future<void> init() async {
    if (kIsWeb) return;
    // При наличии пакета health: вызвать Health().configure()
    debugPrint('HealthService initialized (stub mode)');
  }

  /// Проверить наличие разрешений для метрики.
  Future<bool> hasPermission(HealthMetric metric) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefPrefix${metric.key}') ?? false;
  }

  /// Запросить разрешение для метрики.
  Future<bool> requestPermission(HealthMetric metric) async {
    // STUB: всегда возвращает true в dev-режиме.
    // При наличии пакета health: Health().requestAuthorization([...])
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix${metric.key}', true);
    debugPrint('HealthService: permission granted for ${metric.key}');
    return true;
  }

  /// Прочитать значение метрики за сегодня.
  Future<HealthReadResult> readTodayValue(HealthMetric metric) async {
    if (kIsWeb) {
      return HealthReadResult(
        metric: metric,
        value: 0,
        readAt: DateTime.now(),
        isPermissionDenied: true,
      );
    }

    final hasPerms = await hasPermission(metric);
    if (!hasPerms) {
      return HealthReadResult(
        metric: metric,
        value: 0,
        readAt: DateTime.now(),
        isPermissionDenied: true,
      );
    }

    // STUB: симулируем реалистичные значения для демонстрации.
    // В реальном приложении: Health().getHealthDataFromTypes(...)
    final stubbedValue = _stubbedValue(metric);
    debugPrint('HealthService: read ${metric.key} = $stubbedValue (stub)');

    return HealthReadResult(
      metric: metric,
      value: stubbedValue,
      readAt: DateTime.now(),
    );
  }

  /// Проверяет, достигнута ли цель для автоматического чекина.
  Future<bool> isGoalReached({
    required HealthMetric metric,
    required double targetValue,
  }) async {
    final result = await readTodayValue(metric);
    if (result.isPermissionDenied) return false;
    return result.value >= targetValue;
  }

  /// Попытка автоматического чекина на основе Health данных.
  ///
  /// Возвращает значение метрики, если цель достигнута, иначе null.
  Future<double?> tryAutoCheckin({
    required HealthMetric metric,
    required double targetValue,
  }) async {
    final result = await readTodayValue(metric);
    if (result.isPermissionDenied || result.value < targetValue) return null;
    return result.value;
  }

  double _stubbedValue(HealthMetric metric) {
    final hour = DateTime.now().hour;
    return switch (metric) {
      HealthMetric.steps => (hour * 800).toDouble().clamp(0, 12000),
      HealthMetric.sleepHours => 7.5,
      HealthMetric.activeMinutes => (hour * 3).toDouble().clamp(0, 90),
      HealthMetric.heartRateAvg => 72.0,
      HealthMetric.waterMl => (hour * 100).toDouble().clamp(0, 2500),
      HealthMetric.caloriesBurned => (hour * 60).toDouble().clamp(0, 800),
    };
  }
}
