import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  HabitProgressBar
// ──────────────────────────────────────────────────────────────────────────────

/// Linear progress bar for habit completion tracking.
///
/// ### Spec (DESIGN.md §2)
/// - Height: 8 px
/// - Track: surface colour at 50 % opacity
/// - Fill: primary gradient (`primaryDay` / `primaryNight`)
/// - Fill animation: 800 ms `easeOutQuart`
/// - Completion pulse: brightness flash when [value] reaches 1.0
///
/// [value] must be in `0.0 … 1.0`. Values outside this range are clamped.
///
/// ```dart
/// HabitProgressBar(value: habit.completionRatio)       // 0.0 – 1.0
/// HabitProgressBar(value: 0.72, label: '18 / 25 days') // with label
/// ```
class HabitProgressBar extends StatefulWidget {
  const HabitProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.borderRadius = 999.0,
    this.label,
    this.showLabel = false,
  });

  /// Progress fraction — clamped to [0.0, 1.0].
  final double value;

  /// Bar height. Defaults to 8 px.
  final double height;

  /// Corner radius. Defaults to pill shape.
  final double borderRadius;

  /// Optional text rendered to the right of the bar.
  final String? label;

  /// When `true` the [label] (or the percentage string) is shown.
  final bool showLabel;

  @override
  State<HabitProgressBar> createState() => _HabitProgressBarState();
}

class _HabitProgressBarState extends State<HabitProgressBar>
    with SingleTickerProviderStateMixin {
  // ── Fill animation ───────────────────────────────────────────────────────
  late AnimationController _fillCtrl;
  late Animation<double> _fillAnim;

  // ── Completion pulse animations ──────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();

    _fillCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.progressBarFillDuration, // 800 ms
      value: widget.value.clamp(0.0, 1.0),
    );
    _fillAnim = CurvedAnimation(
      parent: _fillCtrl,
      curve: Curves.easeOutQuart,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // brightness pulse: 1.0 → 1.4 → 1.0 (opacity-represented as 0…1 mapping)
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    _previousValue = widget.value.clamp(0.0, 1.0);
    _fillCtrl.value = _previousValue;
  }

  @override
  void didUpdateWidget(HabitProgressBar old) {
    super.didUpdateWidget(old);
    final target = widget.value.clamp(0.0, 1.0);
    if (target != _previousValue) {
      _previousValue = target;
      _fillCtrl.animateTo(
        target,
        duration: AppAnimations.progressBarFillDuration,
        curve: Curves.easeOutQuart,
      );
      if (target >= 1.0) {
        // Delay pulse until fill animation reaches 100 %
        Future.delayed(AppAnimations.progressBarFillDuration, () {
          if (mounted) _pulseCtrl.forward(from: 0.0);
        });
      }
    }
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? AppGradients.primaryNight : AppGradients.primaryDay;
    final trackColor = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        .withAlpha(0x80); // 50 % opacity

    return AnimatedBuilder(
      animation: Listenable.merge([_fillAnim, _pulseAnim]),
      builder: (context, _) {
        final fraction = _fillAnim.value;
        final pulse = _pulseAnim.value; // 0…1 extra brightness

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth == double.infinity
                ? 200.0
                : constraints.maxWidth;

            return Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: widget.height,
                    child: CustomPaint(
                      painter: _ProgressBarPainter(
                        fraction: fraction,
                        trackColor: trackColor,
                        gradient: gradient,
                        borderRadius: widget.borderRadius,
                        totalWidth: totalWidth,
                        pulseAlpha: pulse,
                      ),
                    ),
                  ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label ??
                        '${(fraction * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _ProgressBarPainter
// ──────────────────────────────────────────────────────────────────────────────

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.fraction,
    required this.trackColor,
    required this.gradient,
    required this.borderRadius,
    required this.totalWidth,
    required this.pulseAlpha,
  });

  final double fraction;
  final Color trackColor;
  final LinearGradient gradient;
  final double borderRadius;
  final double totalWidth;

  /// 0…1 extra glow overlay alpha driven by the completion pulse animation.
  final double pulseAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(borderRadius);
    final trackRect = Offset.zero & size;
    final fillWidth = size.width * fraction;

    // ── Track ───────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, r),
      Paint()..color = trackColor,
    );

    if (fraction <= 0.0) return;

    // ── Gradient fill — clipped to fillRect ─────────────────────────────────
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, fillWidth + borderRadius, size.height),
      r,
    ));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), // full width for gradient
        r,
      ),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // ── Completion brightness pulse — white overlay ─────────────────────────
    if (pulseAlpha > 0.0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          r,
        ),
        Paint()
          ..color = Colors.white.withAlpha((pulseAlpha * 0x66).round()),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProgressBarPainter old) =>
      old.fraction != fraction ||
      old.pulseAlpha != pulseAlpha ||
      old.trackColor != trackColor ||
      old.gradient != gradient;
}
