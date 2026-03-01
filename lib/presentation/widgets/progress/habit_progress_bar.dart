import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  HabitProgressBar
// ──────────────────────────────────────────────────────────────────────────────

/// Линейная полоса прогресса для отслеживания выполнения привычки.
///
/// ### Спецификация (DESIGN.md §2)
/// - Высота: 8 пт
/// - Дорожка: цвет поверхности 50 %
/// - Заливка: градиент primary
/// - Анимация: 800 мс `easeOutQuart`
/// - Импульс завершения при [value] = 1.0
///
/// [value] должен быть в диапазоне `0.0 … 1.0`.
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

  /// Доля прогресса — ограничена диапазоном [0.0, 1.0].
  final double value;

  /// Высота полосы. По умолчанию 8 пт.
  final double height;

  /// Радиус скругления. По умолчанию — форма пилюли.
  final double borderRadius;

  /// Опциональный текст справа от полосы.
  final String? label;

  /// Если `true` — [label] или строка с процентами отображается.
  final bool showLabel;

  @override
  State<HabitProgressBar> createState() => _HabitProgressBarState();
}

class _HabitProgressBarState extends State<HabitProgressBar>
    with SingleTickerProviderStateMixin {
  // ── Анимация заполнения ─────────────────────────────────────────────────
  late AnimationController _fillCtrl;
  late Animation<double> _fillAnim;

  // ── Анимации импульса завершения ──────────────────────────────────────
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
    // пульс яркости: 1.0 → 1.4 → 1.0 (представлен через 0…1)
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
        // Задержка импульса до завершения анимации заполнения
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

  // ── Сборка ────────────────────────────────────────────────────────────────

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

  /// Альфа 0…1 дополнительного светового оверлея при импульсе.
  final double pulseAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(borderRadius);
    final trackRect = Offset.zero & size;
    final fillWidth = size.width * fraction;

    // ── Дорожка ──────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, r),
      Paint()..color = trackColor,
    );

    if (fraction <= 0.0) return;

    // ── Градиентная заливка — обрезана по fillRect ──────────────────────────
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

    // ── Импульс яркости — белый оверлей ─────────────────────────────────────
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
