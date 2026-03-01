import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Типографика дизайн-системы Premium Glass.
///
/// Шрифт: Inter (400/500/600/700) через `google_fonts`.
///
/// Названные геттеры (`h1` … `overline`) соответствуют DESIGN.md §2.3.
/// [toTextTheme] преобразует их в Flutter [TextTheme].
abstract final class AppTypography {
  // ══════════════════════════════════════════════════════════════════
  //  НАЗВАННЫЕ СТИЛИ  (DESIGN.md §2.3)
  // ══════════════════════════════════════════════════════════════════

  /// H1 — заголовки экранов, hero-метки.
  /// 32 px · w700 · height 1.2 · ls -0.64
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.64,
  );

  /// H2 — заголовки секций.
  /// 24 px · w600 · height 1.3 · ls -0.24
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.24,
  );

  /// H3 — подзаголовки, заголовки карточек.
  /// 20 px · w600 · height 1.4 · ls 0
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Subtitle — подзаголовок, заголовки групп списка.
  /// 18 px · w500 · height 1.5 · ls 0
  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Body Large — основной читаемый контент.
  /// 16 px · w400 · height 1.6 · ls 0
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  /// Body — стандартный текст.
  /// 14 px · w400 · height 1.6 · ls 0
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  /// Caption — время, метаданные, вспомогательный текст.
  /// 12 px · w500 · height 1.5 · ls 0.12
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.12,
  );

  /// Button — метка на кнопках.
  /// 16 px · w600 · height 1.0 · ls 0.32
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.32,
  );

  /// Overline — категории, pill-теги, текст значков.
  /// 11 px · w600 · height 1.0 · ls 0.55
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.55,
  );

  // ══════════════════════════════════════════════════════════════════
  //  СПЕЦИАЛЬНЫЕ СТИЛИ
  // ══════════════════════════════════════════════════════════════════

  /// Большое hero-число — счётчик серии, дни, крупные числа.
  /// 64 px · w800 · height 1.0 · ls -1.28
  static TextStyle get numeralHero => GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.28,
  );

  /// Среднее stat-число — значи, вторичные счётчики.
  /// 36 px · w700 · height 1.0 · ls -0.72
  static TextStyle get numeralMedium => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.72,
  );

  /// Малая метка кнопки — вторичные действия.
  /// 14 px · w600 · height 1.0 · ls 0.28
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.28,
  );

  /// Текст в полях ввода.
  /// 16 px · w400 · height 1.5 · ls 0
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // ══════════════════════════════════════════════════════════════════
  //  ПОСТРОИТЕЛЬ TextTheme
  // ══════════════════════════════════════════════════════════════════

  /// Создаёт [TextTheme] для [ThemeData].
  ///
  /// [primaryColor] — основной текст, [secondaryColor] — вторичный, [mutedColor] — приглушённый.
  static TextTheme toTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      // Заголовки экранов
      displayLarge: numeralHero.copyWith(color: primaryColor),
      displayMedium: h1.copyWith(color: primaryColor),
      displaySmall: h2.copyWith(color: primaryColor),

      // Заголовки секций
      headlineLarge: h1.copyWith(color: primaryColor),
      headlineMedium: h2.copyWith(color: primaryColor),
      headlineSmall: h3.copyWith(color: primaryColor),

      // Названия карточек / групп
      titleLarge: subtitle.copyWith(color: primaryColor),
      titleMedium: bodyLarge.copyWith(
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      titleSmall: body.copyWith(fontWeight: FontWeight.w500, color: primaryColor),

      // Основной текст
      bodyLarge: bodyLarge.copyWith(color: secondaryColor),
      bodyMedium: body.copyWith(color: secondaryColor),
      bodySmall: caption.copyWith(color: mutedColor),

      // Метки, чипсы, теги
      labelLarge: button.copyWith(color: primaryColor),
      labelMedium: caption.copyWith(color: primaryColor),
      labelSmall: overline.copyWith(color: mutedColor),
    );
  }
}
