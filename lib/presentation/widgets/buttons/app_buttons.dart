import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Shared constants
// ──────────────────────────────────────────────────────────────────────────────

const _kPressScaleDown = 0.96;
const _kPressOpacity   = 0.80;
const _kPressDuration  = Duration(milliseconds: 150);
const _kPressCurve     = Curves.easeOut;

const _kBorderRadius   = AppSpacing.radiusMd; // 12 px (spec)
const _kVerticalPad    = AppSpacing.base;       // 16 px (spec)
const _kHorizontalPad  = AppSpacing.xl;         // 24 px

/// Greyscale colour-filter for the disabled state.
const ColorFilter _kGreyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
]);

// ──────────────────────────────────────────────────────────────────────────────
//  _PressableButton  (internal base)
// ──────────────────────────────────────────────────────────────────────────────

/// Handles the press scale + opacity animation shared by all button variants.
///
/// Subclasses supply [buildInner] which receives the current [pressed] state
/// so they can tint / re-draw their own chrome if needed.
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

  /// `null` renders the button in [isDisabled] state without calling setState.
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  /// Build the button's visual chrome. [pressed] is `true` while the finger
  /// is held down, allowing subclasses to darken borders etc.
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

    // Disabled: greyscale + 50 % opacity
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

/// Gradient-fill CTA button.
///
/// - Background: `AppGradients.primaryDay` / `primaryNight`
/// - Border radius: 12 px, vertical padding: 16 px (DESIGN.md spec)
/// - Press: scale → 0.96, opacity → 0.80, 150 ms easeOut
/// - Loading: `CircularProgressIndicator` replaces label
/// - Disabled: greyscale + 0.5 opacity
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
        // Pressed inner shadow to reinforce depth
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

/// Outlined button with gradient border stroke and transparent background.
///
/// Uses a `CustomPaint` gradient border so the stroke inherits the same
/// ocean-blue → cyan / rose → blush colours as [PrimaryButton].
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

  /// When `true` the border uses the secondary (coral/rose) gradient instead
  /// of the primary (ocean/sky) gradient.
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

    // Derive a single solid colour from the gradient for the label / icon
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

/// Completely transparent button — text + optional icon only.
///
/// Used for de-emphasised actions such as "Skip", "Later", or inline text-links.
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
//  _ButtonContent  (shared inner layout)
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

/// Paints a rounded-rectangle gradient stroke around a widget.
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
