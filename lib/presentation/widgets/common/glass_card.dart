import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Enumerations
// ──────────────────────────────────────────────────────────────────────────────

/// Visual depth variant for [GlassCard].
///
/// | Variant   | Blur | Shadow depth   | Opacity modifier |
/// |-----------|------|----------------|-----------------|
/// | `default` | 20   | card           | 1.0             |
/// | `elevated`| 20   | elevated + glow| 1.0             |
/// | `flat`    | 12   | none           | 0.8             |
enum GlassCardVariant {
  /// Standard glass card — card-level shadow, full opacity.
  defaultCard,

  /// Lifted glass card — elevated shadow + optional Night glow ring.
  elevated,

  /// Flush glass panel — no shadow, reduced blur, slightly lower opacity.
  flat,
}

/// Optional outer glow colour applied in Night (dark) mode only.
///
/// Matches the `glow-*` shadow tokens from DESIGN.md §2.6.
enum GlassGlowType {
  none,

  /// `0 0 20px rgba(56,189,248,0.25)` — primary sky-blue.
  primary,

  /// `0 0 20px rgba(251,113,133,0.25)` — secondary rose.
  secondary,

  /// `0 0 20px rgba(52,211,153,0.25)` — success emerald.
  success,
}

// ──────────────────────────────────────────────────────────────────────────────
//  GlassCard
// ──────────────────────────────────────────────────────────────────────────────

/// Premium Glass card component.
///
/// Renders a frosted-glass surface using [BackdropFilter] and adapts all
/// visual properties — background opacity, border opacity, box shadows, and
/// glow rings — to the current theme brightness automatically.
///
/// ### Variants
/// - [GlassCardVariant.defaultCard] — standard card depth.
/// - [GlassCardVariant.elevated]   — raised card with deeper shadow / Night glow.
/// - [GlassCardVariant.flat]       — borderless, minimal-shadow panel.
///
/// ### Shimmer animation
/// Set [shimmer] to `true` to enable a continuous diagonal gradient sweep
/// across the glass surface that adds a subtle premium sheen.
///
/// ```dart
/// GlassCard(
///   variant: GlassCardVariant.elevated,
///   glow: GlassGlowType.primary,
///   shimmer: true,
///   child: Text('Level 5'),
/// )
/// ```
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.defaultCard,
    this.glow = GlassGlowType.none,
    this.shimmer = false,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  /// Content rendered inside the glass surface.
  final Widget child;

  /// Shadow / depth variant. Defaults to [GlassCardVariant.defaultCard].
  final GlassCardVariant variant;

  /// Outer glow colour applied in dark mode only.
  /// Has no effect in light mode or when [variant] is [GlassCardVariant.flat].
  final GlassGlowType glow;

  /// When `true`, a diagonal shimmer gradient slowly sweeps across the surface.
  final bool shimmer;

  /// Corner radius. Defaults to [AppSpacing.radiusLg] (16 px).
  final BorderRadius? borderRadius;

  /// Inner padding. Defaults to [AppSpacing.base] (16 px) on all sides.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Tap callback. When provided the card gains a subtle press scale.
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  // ── Shimmer controller ───────────────────────────────────────────────────
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  // ── Press state ──────────────────────────────────────────────────────────
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    if (widget.shimmer) {
      _shimmerController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer && !oldWidget.shimmer) {
      _shimmerController.repeat(reverse: true);
    } else if (!widget.shimmer && oldWidget.shimmer) {
      _shimmerController.stop();
      _shimmerController.reset();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double get _blurSigma => switch (widget.variant) {
    GlassCardVariant.flat => 12.0,
    _ => 20.0,
  };

  Color _resolveBackground(bool isDark) {
    final baseOpacity = widget.variant == GlassCardVariant.flat ? 0.85 : 1.0;

    if (isDark) {
      // Night: charcoal at 60 %  →  flat: slightly less opaque
      return Color.fromARGB(
        (0x99 * baseOpacity).round(), // 0x99 = 153 ≈ 60 %
        0x1C,
        0x19,
        0x17,
      );
    } else {
      // Day: white at 70 %  →  flat: slightly more transparent
      return Color.fromARGB(
        (0xB3 * baseOpacity).round(), // 0xB3 = 179 ≈ 70 %
        0xFF,
        0xFF,
        0xFF,
      );
    }
  }

  Color _resolveBorderColor(bool isDark) {
    if (isDark) {
      // Night: 5 % white; elevated gets 8 % for extra definition
      final alpha = widget.variant == GlassCardVariant.elevated ? 0x14 : 0x0D;
      return Color.fromARGB(alpha, 0xFF, 0xFF, 0xFF);
    } else {
      // Day: 20 % white; elevated gets 26 % for extra definition
      final alpha = widget.variant == GlassCardVariant.elevated ? 0x42 : 0x33;
      return Color.fromARGB(alpha, 0xFF, 0xFF, 0xFF);
    }
  }

  double _resolveBorderWidth() =>
      widget.variant == GlassCardVariant.flat ? 0.0 : 1.0;

  List<BoxShadow> _resolveShadows(bool isDark) {
    if (widget.variant == GlassCardVariant.flat) return const [];

    if (isDark) {
      return [
        // ── Base shadow ─────────────────────────────────────────────────
        ..._darkBaseShadow,
        // ── Night glow ring ─────────────────────────────────────────────
        if (widget.glow != GlassGlowType.none &&
            widget.variant == GlassCardVariant.elevated)
          _nightGlow(widget.glow),
      ];
    } else {
      return _lightBaseShadow;
    }
  }

  List<BoxShadow> get _lightBaseShadow {
    return switch (widget.variant) {
      GlassCardVariant.elevated => const [
        BoxShadow(
          color: Color(0x1A000000), // rgba(0,0,0,0.10)
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x0F000000), // rgba(0,0,0,0.06)
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      _ => const [
        BoxShadow(
          color: Color(0x1A000000), // rgba(0,0,0,0.10)
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0F000000), // rgba(0,0,0,0.06)
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    };
  }

  List<BoxShadow> get _darkBaseShadow {
    return switch (widget.variant) {
      GlassCardVariant.elevated => const [
        BoxShadow(
          color: Color(0x66000000), // rgba(0,0,0,0.40)
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x33000000), // rgba(0,0,0,0.20)
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      _ => const [
        BoxShadow(
          color: Color(0x4D000000), // rgba(0,0,0,0.30)
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x33000000), // rgba(0,0,0,0.20)
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    };
  }

  BoxShadow _nightGlow(GlassGlowType type) {
    return switch (type) {
      GlassGlowType.primary => const BoxShadow(
        color: Color(0x4038BDF8), // rgba(56,189,248,0.25)
        blurRadius: 20,
        spreadRadius: 0,
      ),
      GlassGlowType.secondary => const BoxShadow(
        color: Color(0x40FB7185), // rgba(251,113,133,0.25)
        blurRadius: 20,
        spreadRadius: 0,
      ),
      GlassGlowType.success => const BoxShadow(
        color: Color(0x4034D399), // rgba(52,211,153,0.25)
        blurRadius: 20,
        spreadRadius: 0,
      ),
      GlassGlowType.none => const BoxShadow(color: AppColors.transparent),
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final bgColor = _resolveBackground(isDark);
    final borderColor = _resolveBorderColor(isDark);
    final borderWidth = _resolveBorderWidth();
    final shadows = _resolveShadows(isDark);
    final padding =
        widget.padding ?? const EdgeInsets.all(AppSpacing.base);

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _blurSigma,
            sigmaY: _blurSigma,
          ),
          child: Stack(
            children: [
              // ── Glass shimmer overlay ─────────────────────────────────
              if (widget.shimmer) _ShimmerOverlay(animation: _shimmerAnimation),

              // ── Content ───────────────────────────────────────────────
              Padding(
                padding: padding,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap in margin if provided
    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    // Interactive press feedback
    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap!();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  Shimmer Overlay
// ──────────────────────────────────────────────────────────────────────────────

/// Internal widget that paints a slowly drifting diagonal gradient shimmer
/// across the glass surface.
///
/// The [animation] value (0.0 → 1.0 → 0.0, looping) drives the gradient's
/// [LinearGradient.begin] and [LinearGradient.end] alignment, creating a
/// smooth sweep from top-left to bottom-right and back.
class _ShimmerOverlay extends AnimatedWidget {
  const _ShimmerOverlay({required Animation<double> animation})
    : super(listenable: animation);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _animation.value; // 0.0 → 1.0

    // Shift the gradient begin/end diagonally as t progresses
    final begin = Alignment(-1.5 + t * 3.0, -1.5 + t * 1.5);
    final end = Alignment(-0.5 + t * 3.0, -0.5 + t * 1.5);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: const [
              Color(0x00FFFFFF), //  0 % white — leading edge
              Color(0x0CFFFFFF), //  5 % white — shimmer peak
              Color(0x1AFFFFFF), // 10 % white — core glow
              Color(0x0CFFFFFF), //  5 % white — trailing taper
              Color(0x00FFFFFF), //  0 % white — trailing edge
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
