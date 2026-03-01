import 'package:flutter/material.dart';

/// Цветовая палитра дизайн-системы Premium Glass.
///
/// `light*` — токены светлой темы, `dark*` — тёмной.
/// Бренд-цвета без префикса — дневные варианты; с суффиксом `*Night` — ночные.
abstract final class AppColors {
  // ══════════════════════════════════════════════════════════════════
  //  СВЕТЛАЯ ТЕМА
  // ══════════════════════════════════════════════════════════════════

  /// Белый жемчуг — фон экранов.
  static const Color lightBackground = Color(0xFFFAFAF9);

  /// Чистый белый — карточки, модальные окна, поля ввода.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Светло-серый — hover-состояния, выделенные блоки.
  static const Color lightSurfaceElevated = Color(0xFFF5F5F4);

  /// Фон стеклянной карточки: белый 70%.
  static const Color lightGlassBackground = Color(0xB3FFFFFF);

  /// Граница стеклянной карточки: белый 20%.
  static const Color lightGlassBorder = Color(0x33FFFFFF);

  /// Графит — заголовки, основной текст.
  static const Color lightTextPrimary = Color(0xFF1C1917);

  /// Серый камень — подписи, метаданные.
  static const Color lightTextSecondary = Color(0xFF78716C);

  /// Светло-серый — плейсхолдеры, отключённый текст.
  static const Color lightTextMuted = Color(0xFFA8A29E);

  /// Тёплый серый — разделители, границы карточек.
  static const Color lightBorder = Color(0xFFE7E5E4);

  // ══════════════════════════════════════════════════════════════════
  //  ТЁМНАЯ ТЕМА
  // ══════════════════════════════════════════════════════════════════

  /// Тёмный графит — фон экранов.
  static const Color darkBackground = Color(0xFF0C0A09);

  /// Графит — карточки, модальные окна, поля ввода.
  static const Color darkSurface = Color(0xFF1C1917);

  /// Тёплый графит — hover-состояния, приподнятые блоки.
  static const Color darkSurfaceElevated = Color(0xFF292524);

  /// Фон стеклянной карточки: графит 60%.
  static const Color darkGlassBackground = Color(0x991C1917);

  /// Glass card border: white at 5 % opacity.
  static const Color darkGlassBorder = Color(0x0DFFFFFF);

  /// Off-white — headings, primary body text.
  static const Color darkTextPrimary = Color(0xFFFAFAF9);

  /// Тёплый серый — подписи, метаданные.
  static const Color darkTextSecondary = Color(0xFFA8A29E);

  /// Тёмный серый — плейсхолдеры, отключённый текст.
  static const Color darkTextMuted = Color(0xFF78716C);

  /// Тёмная линия разделителя.
  static const Color darkBorder = Color(0xFF44403C);

  // ══════════════════════════════════════════════════════════════════
  //  БРЕНД-ЦВЕТА
  // ══════════════════════════════════════════════════════════════════

  // ── Основной (Primary)

  /// Океанский синий — CTA, прогресс, активные элементы (светлая).
  static const Color primary = Color(0xFF0EA5E9);

  /// Небесно-голубой — CTA, прогресс, активные элементы (тёмная).
  static const Color primaryNight = Color(0xFF38BDF8);

  /// Тёмный цвет для контейнеров / нажатого состояния (светлая).
  static const Color primaryContainer = Color(0xFF0369A1);

  /// Тёмный цвет для контейнеров / нажатого состояния (тёмная).
  static const Color primaryContainerNight = Color(0xFF0EA5E9);

  // \u2500\u2500 \u0414\u043e\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439 (Secondary)

  /// Коралловый — противник, VS, дуэли (светлая).
  static const Color secondary = Color(0xFFF43F5E);

  /// Розовый — противник, VS (тёмная).
  static const Color secondaryNight = Color(0xFFFB7185);

  /// Тёмно-розовый контейнер (светлая).
  static const Color secondaryContainer = Color(0xFF9F1239);

  /// Мягкий розовый контейнер (тёмная).
  static const Color secondaryContainerNight = Color(0xFFBE123C);

  // \u2500\u2500 \u0422\u0440\u0435\u0442\u0438\u0447\u043d\u044b\u0439 (Tertiary)

  /// Мятно-зелёный — успех, выполнение, победа (светлая).
  static const Color tertiary = Color(0xFF10B981);

  /// Изумрудный — успех, победа (тёмная).
  static const Color tertiaryNight = Color(0xFF34D399);

  // \u2500\u2500 \u041f\u0440\u0435\u0434\u0443\u043f\u0440\u0435\u0436\u0434\u0435\u043d\u0438\u0435 (Warning)

  /// Янтарь — напоминания, прерыв серии (светлая).
  static const Color warning = Color(0xFFF59E0B);

  /// Золотой — напоминания, предупреждения (тёмная).
  static const Color warningNight = Color(0xFFFBBF24);

  // \u2500\u2500 \u041e\u0448\u0438\u0431\u043a\u0430 / \u041e\u043f\u0430\u0441\u043d\u043e\u0441\u0442\u044c (Error)

  /// Красный — ошибки, поражение, прерванная серия.
  static const Color error = Color(0xFFEF4444);

  // \u2500\u2500 \u0414\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f (Achievement)

  /// Золотой — кубки, значки.
  static const Color gold = Color(0xFFFFD700);

  // ══════════════════════════════════════════════════════════════════
  //  ВСПОМОГАТЕЛЬНЫЕ
  // ══════════════════════════════════════════════════════════════════

  /// Полупрозрачная пелена поверх модальных окон.
  static const Color scrim = Color(0x80000000);

  /// Прозрачный цвет.
  static const Color transparent = Colors.transparent;
}

