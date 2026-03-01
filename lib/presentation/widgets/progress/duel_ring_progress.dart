import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Enumerations
// ──────────────────────────────────────────────────────────────────────────────

/// Predefined outer diameter for [DuelRingProgress].
enum DuelRingSize {
  /// 120 px outer diameter — compact duel card.
  medium,

  /// 160 px outer diameter — hero / VS screen.
  large,
}

// ──────────────────────────────────────────────────────────────────────────────
//  DuelRingProgress
// ──────────────────────────────────────────────────────────────────────────────

/// Circular progress ring designed for duel participant display.
///
/// ### Spec
/// - Sizes: `medium` = 120 px, `large` = 160 px
/// - Stroke width: 12 px
/// - Track: surface colour at 30 % opacity
/// - Progress arc: primary gradient (`primaryDay` / `primaryNight`)
/// - Arc start: top-centre (−90°), sweeps clockwise
/// - Animation: 800 ms `easeOutQuart` on [value] change
/// - Centre: accepts any widget (typically a [UserAvatar])
///
/// ```dart
/// DuelRingProgress(
///   value: participant.progress,          // 0.0 – 1.0
///   size: DuelRingSize.large,
///   center: UserAvatar(
///     size: AvatarSize.large,
///     imageUrl: participant.avatarUrl,
///     name: participant.name,
///   ),
/// )
/// ```
class DuelRingProgress extends StatefulWidget {
  const DuelRingProgress({
    super.key,
    required this.value,
    this.size = DuelRingSize.medium,
    this.center,
    this.strokeWidth = 12.0,
    this.useSecondaryGradient = false,
    this.trackOpacity = 0.30,
  });

  /// Progress fraction — clamped to [0.0, 1.0].
  final double value;

  /// Outer diameter preset.
  final DuelRingSize size;

  /// Widget rendered at the centre of the ring (e.g. a [UserAvatar]).
  final Widget? center;

  /// Arc stroke width. Defaults to 12 px.
  final double strokeWidth;

  /// Set `true` to use the secondary (coral/rose) gradient — for the opponent.
  final bool useSecondaryGradient;

  /// Track circle opacity. Defaults to 30 %.
  final double trackOpacity;

  @override
  State<DuelRingProgress> createState() => _DuelRingProgressState();
}

class _DuelRingProgressState extends State<DuelRingProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppAnimations.progressBarFillDuration, // 800 ms
      value: widget.value.clamp(0.0, 1.0),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
  }

  @override
  void didUpdateWidget(DuelRingProgress old) {
    super.didUpdateWidget(old);
    final target = widget.value.clamp(0.0, 1.0);
    if (target != old.value.clamp(0.0, 1.0)) {
      _ctrl.animateTo(
        target,
        duration: AppAnimations.progressBarFillDuration,
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diameter = widget.size == DuelRingSize.large ? 160.0 : 120.0;

    LinearGradient gradient;
    if (widget.useSecondaryGradient) {
      gradient = isDark ? AppGradients.secondaryNight : AppGradients.secondaryDay;
    } else {
      gradient = isDark ? AppGradients.primaryNight : AppGradients.primaryDay;
    }

    final trackColor =
        (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withAlpha((widget.trackOpacity * 255).round());

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: _anim.value,
              gradient: gradient,
              trackColor: trackColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: child,
          ),
        );
      },
      child: widget.center != null
          ? Center(child: widget.center)
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _RingPainter
// ──────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.gradient,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double fraction;
  final LinearGradient gradient;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track circle ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    if (fraction <= 0.0) return;

    // ── Gradient progress arc ─────────────────────────────────────────────────
    final sweepAngle = 2 * math.pi * fraction;
    final startAngle = -math.pi / 2; // top-centre

    // Draw the arc using a gradient shader — the shader rect covers the full
    // bounding box so the gradient orientation aligns top-left → bottom-right
    // regardless of the arc length.
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);

    // ── Leading dot at the arc tip ────────────────────────────────────────────
    // A filled circle at the tip makes the end cap look like a proper nib.
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    canvas.drawCircle(
      Offset(tipX, tipY),
      strokeWidth / 2,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.gradient != gradient ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
