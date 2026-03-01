import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Корневой ThemeData дизайн-системы Premium Glass.
///
/// Цвета, типографика, радиусы и умолчания берутся из
/// [AppColors], [AppTypography] и [AppSpacing].
abstract final class AppTheme {
  // ── Публичные точки входа ─────────────────────────────────────────────────────────

  static ThemeData get light => _build(isDark: false);
  static ThemeData get dark  => _build(isDark: true);

  // ── Внутренний будьовщик ───────────────────────────────────────────────────────

  static ThemeData _build({required bool isDark}) {
    // ── Палитра цветов ─────────────────────────────────────────────────────
    final bg             = isDark ? AppColors.darkBackground      : AppColors.lightBackground;
    final surface        = isDark ? AppColors.darkSurface         : AppColors.lightSurface;
    final surfaceElev    = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final glassBg        = isDark ? AppColors.darkGlassBackground : AppColors.lightGlassBackground;
    final glassBorder    = isDark ? AppColors.darkGlassBorder     : AppColors.lightGlassBorder;
    final textPrimary    = isDark ? AppColors.darkTextPrimary     : AppColors.lightTextPrimary;
    final textSecondary  = isDark ? AppColors.darkTextSecondary   : AppColors.lightTextSecondary;
    final textMuted      = isDark ? AppColors.darkTextMuted       : AppColors.lightTextMuted;
    final borderColor    = isDark ? AppColors.darkBorder          : AppColors.lightBorder;
    final primaryColor   = isDark ? AppColors.primaryNight        : AppColors.primary;
    final secondaryColor = isDark ? AppColors.secondaryNight      : AppColors.secondary;
    final tertiaryColor  = isDark ? AppColors.tertiaryNight       : AppColors.tertiary;
    final brightness     = isDark ? Brightness.dark               : Brightness.light;

    // Контраст иконок статус-бара
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    // \u2500\u2500 ColorScheme
    final colorScheme = ColorScheme(
      brightness: brightness,

      // Primary
      primary: primaryColor,
      onPrimary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      primaryContainer: isDark
          ? AppColors.primaryContainerNight
          : AppColors.primaryContainer,
      onPrimaryContainer: isDark ? AppColors.darkTextPrimary : AppColors.lightSurface,

      // Secondary
      secondary: secondaryColor,
      onSecondary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      secondaryContainer: isDark
          ? AppColors.secondaryContainerNight
          : AppColors.secondaryContainer,
      onSecondaryContainer: isDark ? AppColors.darkTextPrimary : AppColors.lightSurface,

      // Tertiary
      tertiary: tertiaryColor,
      onTertiary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      tertiaryContainer: isDark
          ? const Color(0xFF065F46) // emerald-900
          : const Color(0xFFD1FAE5), // emerald-100
      onTertiaryContainer: isDark ? AppColors.tertiaryNight : AppColors.tertiary,

      // Error
      error: AppColors.error,
      onError: AppColors.lightSurface,
      errorContainer: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
      onErrorContainer: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),

      // Поверхности
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceElev,
      onSurfaceVariant: textSecondary,

      // Фон экрана
      // ignore: deprecated_member_use
      background: bg,
      // ignore: deprecated_member_use
      onBackground: textPrimary,

      // Границы / разделители
      outline: borderColor,
      outlineVariant: glassBorder,

      // Прочее
      shadow: Colors.black,
      scrim: AppColors.scrim,
      inverseSurface: isDark ? AppColors.lightSurface  : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      inversePrimary: isDark ? AppColors.primary : AppColors.primaryNight,
    );

    // \u2500\u2500 ThemeData
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,

      // \u2500\u2500 \u0422\u0438\u043f\u043e\u0433\u0440\u0430\u0444\u0438\u043a\u0430
      textTheme: AppTypography.toTextTheme(
        primaryColor: textPrimary,
        secondaryColor: textSecondary,
        mutedColor: textMuted,
      ),

      // \u2500\u2500 AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: textPrimary, size: AppSpacing.iconMd),
        titleTextStyle: AppTypography.h3.copyWith(color: textPrimary),
        centerTitle: false,
      ),

      // \u2500\u2500 \u041a\u0430\u0440\u0442\u043e\u0447\u043a\u0430
      // \u0421\u0442\u0435\u043a\u043b\u044f\u043d\u043d\u0430\u044f \u043a\u0430\u0440\u0442\u043e\u0447\u043a\u0430: \u043f\u043e\u043b\u0443\u043f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u044b\u0439 \u0444\u043e\u043d + \u0442\u043e\u043d\u043a\u0430\u044f \u0433\u0440\u0430\u043d\u0438\u0446\u0430.
      // \u0422\u043e\u043a\u0435\u043d\u044b GlassCard \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438 \u0447\u0438\u0442\u0430\u044e\u0442\u0441\u044f \u0438\u0437 \u0442\u0435\u043c\u044b.
      
      cardTheme: CardThemeData(
        color: glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.itemGap / 2,
        ),
      ),

      // \u2500\u2500 \u041e\u0441\u043d\u043e\u0432\u043d\u0430\u044f \u043a\u043d\u043e\u043f\u043a\u0430
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
          disabledBackgroundColor: glassBg,
          disabledForegroundColor: textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
        ),
      ),

      // \u2500\u2500 \u041a\u043e\u043d\u0442\u0443\u0440\u043d\u0430\u044f \u043a\u043d\u043e\u043f\u043a\u0430
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
        ),
      ),

      // \u2500\u2500 \u0422\u0435\u043a\u0441\u0442\u043e\u0432\u0430\u044f \u043a\u043d\u043e\u043f\u043a\u0430
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      // \u2500\u2500 \u041f\u043e\u043b\u0435 \u0432\u0432\u043e\u0434\u0430 / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.body.copyWith(color: textSecondary),
        hintStyle: AppTypography.body.copyWith(color: textMuted),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // \u2500\u2500 NavigationBar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: primaryColor.withAlpha(40),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: AppSpacing.iconMd);
          }
          return IconThemeData(color: textSecondary, size: AppSpacing.iconMd);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.overline.copyWith(color: primaryColor);
          }
          return AppTypography.overline.copyWith(color: textSecondary);
        }),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
      ),

      // \u2500\u2500 \u041d\u0438\u0436\u043d\u044f\u044f \u043d\u0430\u0432\u0438\u0433\u0430\u0446\u0438\u0448\u043d\u0430\u044f \u043f\u0430\u043d\u0435\u043b\u044c
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.overline,
        unselectedLabelStyle: AppTypography.overline,
      ),

      // \u2500\u2500 \u0420\u0430\u0437\u0434\u0435\u043b\u0438\u0442\u0435\u043b\u044c
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // \u2500\u2500 \u0418\u043a\u043e\u043d\u043a\u0430
      iconTheme: IconThemeData(color: textSecondary, size: AppSpacing.iconMd),

      // \u2500\u2500 \u0427\u0438\u043f
      chipTheme: ChipThemeData(
        backgroundColor: glassBg,
        selectedColor: primaryColor.withAlpha(50),
        labelStyle: AppTypography.caption.copyWith(color: textPrimary),
        side: BorderSide(color: glassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      // \u2500\u2500 \u0414\u0438\u0430\u043b\u043e\u0433
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElev,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        ),
        titleTextStyle: AppTypography.h3.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: textSecondary),
      ),

      // \u2500\u2500 Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElev,
        contentTextStyle: AppTypography.body.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // \u2500\u2500 \u0418\u043d\u0434\u0438\u043a\u0430\u0442\u043e\u0440 \u043f\u0440\u043e\u0433\u0440\u0435\u0441\u0441\u0430
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: glassBg,
        circularTrackColor: glassBg,
      ),

      // \u2500\u2500 \u041f\u0435\u0440\u0435\u043a\u043b\u044e\u0447\u0430\u0442\u0435\u043b\u044c
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.darkBackground : AppColors.lightSurface;
          }
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return glassBg;
        }),
      ),

      // \u2500\u2500 \u041f\u043b\u0430\u0432\u0430\u044e\u0449\u0430\u044f \u043a\u043d\u043e\u043f\u043a\u0430
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),

      // \u2500\u2500 \u0417\u043d\u0430\u0447\u043e\u043a
      badgeTheme: BadgeThemeData(
        backgroundColor: secondaryColor,
        textColor: AppColors.lightSurface,
        textStyle: AppTypography.overline,
      ),

      // \u2500\u2500 ListTile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: textSecondary,
        titleTextStyle: AppTypography.body.copyWith(color: textPrimary),
        subtitleTextStyle: AppTypography.caption.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
