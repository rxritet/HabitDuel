import 'package:flutter/material.dart';

/// Градиенты дизайн-системы Premium Glass.
///
/// **Primary** — океан-небо (Day) / небо-циан (Night) → CTA, прогресс.
/// **Secondary** — коралл-роза (Day) / роза-блаш (Night) → противник, VS.
/// **Success** — мята-изумруд → выполнение, победа.
/// **Warning** — янтарь-золото → напоминания.
/// **Background Night** — глубокий графит → фон страницы в тёмной теме.
///
/// Суффиксы `*Day` / `*Night` — варианты для светлой / тёмной темы.
abstract final class AppGradients {
  // ══════════════════════════════════════════════════════════════════
  //  ОСНОВНОЙ ГРАДИЕНТ  (Океанский / Небесный синий)
  // ══════════════════════════════════════════════════════════════════

  /// Светлая: #0EA5E9 → #22D3EE (кнопки CTA, активные элементы).
  static const LinearGradient primaryDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
  );

  /// Тёмная: #38BDF8 → #22D3EE (кнопки CTA, активные элементы).
  static const LinearGradient primaryNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF22D3EE)],
  );

  // ══════════════════════════════════════════════════════════════════
  //  ДОПОЛНИТЕЛЬНЫЙ ГРАДИЕНТ  (Коралл / Роза)
  // ══════════════════════════════════════════════════════════════════

  /// Светлая: #F43F5E → #FB7185 (противник, VS).
  static const LinearGradient secondaryDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );

  /// Тёмная: #FB7185 → #FDA4AF (противник, VS).
  static const LinearGradient secondaryNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFFDA4AF)],
  );

  // ══════════════════════════════════════════════════════════════════
  //  ВСПОМОГАТЕЛЬНЫЕ ГРАДИЕНТЫ  (без зависимости от темы)
  // ══════════════════════════════════════════════════════════════════

  /// Успех / победа: #10B981 → #34D399.
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  /// Предупреждение / напоминание: #F59E0B → #FBBF24.
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  /// Фоновый градиент тёмной темы: глубокий графит.
  static const LinearGradient backgroundNight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C0A09), Color(0xFF1C1917), Color(0xFF0C0A09)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Огонь серии: жёлтый → оранжевый → красно-оранжевый.
  static const LinearGradient streak = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE259), Color(0xFFFF8C00), Color(0xFFFF4500)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Золотой жетон: яркое золото → глубокое золото.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE066), Color(0xFFFFD700), Color(0xFFD4A017)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Шиммер стеклянной карточки (gloss-налёт).
  static const LinearGradient glassShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // белый 20%
      Color(0x0DFFFFFF), // белый  5%
      Color(0x1AFFFFFF), // белый 10%
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ══════════════════════════════════════════════════════════════════
  //  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ══════════════════════════════════════════════════════════════════

  /// Возвращает основной градиент для заданной яркости.
  static LinearGradient primary(Brightness brightness) =>
      brightness == Brightness.dark ? primaryNight : primaryDay;

  /// Возвращает дополнительный градиент для заданной яркости.
  static LinearGradient secondary(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryNight : secondaryDay;
}
