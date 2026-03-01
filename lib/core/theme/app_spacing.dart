/// Отступы и размеры дизайн-системы Premium Glass.
///
/// Основа — 4 pt grid. Используйте семантические названия вместо чисел.
abstract final class AppSpacing {
  // ── Базовые отступы (4 pt grid) ─────────────────────────────────────────────

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  // ── Семантические отступы ─────────────────────────────────────────────────────

  /// Внутренний отступ карточек и контейнеров.
  static const double cardPadding = xl; // 24

  /// Горизонтальные поля экрана.
  static const double screenPadding = base; // 16

  /// Интервал между строками списка / карточками.
  static const double itemGap = md; // 12

  /// Интервал между близко связанными элементами.
  static const double inlineGap = sm; // 8

  /// Отступ между полями формы.
  static const double formFieldGap = base; // 16

  /// Вертикальный разделитель секций.
  static const double sectionGap = xxl; // 32

  // ── Радиусы скругления ──────────────────────────────────────────────────────────

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0; // пилюля / округлый

  /// Стандартный радиус углов карточки.
  static const double cardRadius = radiusXl; // 20

  /// Радиус углов кнопки.
  static const double buttonRadius = radiusLg; // 16

  // ── Размеры иконок ────────────────────────────────────────────────────────────

  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Размеры аватаров / изображений ─────────────────────────────────────────────────

  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 80.0;

  // ── Высоты компонентов ─────────────────────────────────────────────────────

  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
}
