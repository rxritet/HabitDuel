import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Общие константы
// ──────────────────────────────────────────────────────────────────────────────

const _kPressScaleDown = 0.96;
const _kPressOpacity   = 0.80;
const _kPressDuration  = Duration(milliseconds: 150);
const _kPressCurve     = Curves.easeOut;

const _kBorderRadius   = AppSpacing.radiusMd; // 12 px (spec)
const _kVerticalPad    = AppSpacing.base;       // 16 px (spec)
const _kHorizontalPad  = AppSpacing.xl;         // 24 px

/// Цветовой фильтр оттенков серого для состояния disabled.
const ColorFilter _kGreyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
]);

// ──────────────────────────────────────────────────────────────────────────────
//  _PressableButton  (внутренняя база)
// ──────────────────────────────────────────────────────────────────────────────

/// Обрабатывает анимацию масштаба + прозрачности, общую для всех вариантов кнопок.
///
/// Подклассы предоставляют [buildInner], который получает состояние [pressed].
abstract class _PressableButton extends StatefulWidget {
  const _PressableButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.textStyle,
  });

  final String label;

  /// `null` переводит кнопку в состояние [isDisabled].
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  /// Отрисовывает визуальную оболочку кнопки. [pressed] = `true` пока палец удержан.
  Widget buildInner(
    BuildContext context, {
    required bool pressed,
    required bool isDark,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kPressDuration);
    _scaleAnim = Tween<double>(begin: 1.0, end: _kPressScaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: _kPressCurve),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: _kPressOpacity).animate(
      CurvedAnimation(parent: _ctrl, curve: _kPressCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _interactive =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _onTapDown(TapDownDetails _) {
    if (!_interactive) return;
    setState(() => _pressed = true);
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_interactive) return;
    _release();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (!_interactive) return;
    _release();
  }

  void _release() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = widget.buildInner(context, pressed: _pressed, isDark: isDark);

    Widget child = AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.scale(
        scale: _scaleAnim.value,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: inner,
        ),
      ),
    );

    // Отключено: оттенки серого + 50 % прозрачности
    if (widget.isDisabled) {
      child = Opacity(
        opacity: 0.5,
        child: ColorFiltered(colorFilter: _kGreyscale, child: child),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PrimaryButton
// ──────────────────────────────────────────────────────────────────────────────

/// Кнопка CTA с градиентной заливкой.
///
/// - Фон: `AppGradients.primaryDay` / `primaryNight`
/// - Радиус: 12 пт, отступ: 16 пт
/// - Нажатие: масштаб → 0.96, прозрачность → 0.80, 150 мс
/// - Загрузка: [CircularProgressIndicator]
/// - Disabled: серые тона + прозрачность 0.5
///
/// ```dart
/// PrimaryButton(
///   label: 'Start Duel',
///   onPressed: _start,
///   isLoading: _loading,
/// )
/// ```
class PrimaryButton extends _PressableButton {
  const PrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isDisabled,
    super.width,
    super.height,
    super.textStyle,
  });

  @override
  Widget buildInner(
    BuildContext context, {
    required bool pressed,
    required bool isDark,
  }) {
    final gradient = isDark ? AppGradients.primaryNight : AppGradients.primaryDay;
    final labelColor = isDark ? AppColors.darkBackground : AppColors.lightSurface;
    final h = height ?? AppSpacing.buttonHeight;

    return Container(
      width: width ?? double.infinity,
      height: h,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        // Внутренняя тень при нажатии для усиления глубины
        boxShadow: pressed
            ? const []
            : [
                BoxShadow(
                  color: Color(0x330EA5E9),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _kHorizontalPad,
        vertical: _kVerticalPad,
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        labelColor: labelColor,
        textStyle: textStyle ?? AppTypography.button,
        indicatorColor: labelColor,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SecondaryButton
// ──────────────────────────────────────────────────────────────────────────────

/// Кнопка с прозрачным фоном и градиентной рамкой.
///
/// Использует `CustomPaint` для градиентного БИ рамки.
///
/// ```dart
/// SecondaryButton(label: 'Cancel', onPressed: _cancel)
/// ```
class SecondaryButton extends _PressableButton {
  const SecondaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isDisabled,
    super.width,
    super.height,
    super.textStyle,
    this.useSecondaryGradient = false,
  });

  /// Если `true` — рамка использует вторичный градиент (coral/rose) вместо primary.
  final bool useSecondaryGradient;

  @override
  Widget buildInner(
    BuildContext context, {
    required bool pressed,
    required bool isDark,
  }) {
    final gradient = useSecondaryGradient
        ? (isDark ? AppGradients.secondaryNight : AppGradients.secondaryDay)
        : (isDark ? AppGradients.primaryNight   : AppGradients.primaryDay);

    // Получаем сплошной цвет из градиента для метки и иконки
    final labelColor = useSecondaryGradient
        ? (isDark ? AppColors.secondaryNight : AppColors.secondary)
        : (isDark ? AppColors.primaryNight   : AppColors.primary);

    final h = height ?? AppSpacing.buttonHeight;

    return CustomPaint(
      painter: _GradientBorderPainter(
        gradient: gradient,
        borderRadius: _kBorderRadius,
        strokeWidth: pressed ? 1.5 : 1.0,
      ),
      child: Container(
        width: width ?? double.infinity,
        height: h,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _kHorizontalPad,
          vertical: _kVerticalPad,
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          labelColor: labelColor,
          textStyle: textStyle ?? AppTypography.button.copyWith(color: labelColor),
          indicatorColor: labelColor,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  GhostButton
// ──────────────────────────────────────────────────────────────────────────────

/// Полностью прозрачная кнопка — только текст и иконка.
///
/// Для неакцентированных действий: «Пропустить», «Позже» и т. п.
///
/// ```dart
/// GhostButton(label: 'Skip for now', onPressed: _skip)
/// ```
class GhostButton extends _PressableButton {
  const GhostButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isDisabled,
    super.width,
    super.height,
    super.textStyle,
  });

  @override
  Widget buildInner(
    BuildContext context, {
    required bool pressed,
    required bool isDark,
  }) {
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: width,
      height: height ?? AppSpacing.buttonHeightSm,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        labelColor: labelColor,
        textStyle: textStyle ??
            AppTypography.buttonSmall.copyWith(color: labelColor),
        indicatorColor: labelColor,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _ButtonContent  (общая внутренняя вёрстка)
// ──────────────────────────────────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.labelColor,
    required this.textStyle,
    required this.indicatorColor,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final Color labelColor;
  final TextStyle textStyle;
  final Color indicatorColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
      );
    }

    final text = Text(
      label,
      style: textStyle.copyWith(color: labelColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (icon == null) {
      return Center(child: text);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: AppSpacing.sm),
        text,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _GradientBorderPainter
// ──────────────────────────────────────────────────────────────────────────────

/// Рисует градиентный скрашенный прямоугольник вокруг виджета.
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final Gradient gradient;
  final double borderRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.strokeWidth != strokeWidth ||
      old.borderRadius != borderRadius ||
      old.gradient != gradient;
}
