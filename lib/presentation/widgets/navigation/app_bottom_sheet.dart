import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  AppBottomSheet
// ──────────────────────────────────────────────────────────────────────────────

/// A glass-styled modal bottom sheet with true spring-physics slide-up
/// entrance and a centered 40 px wide drag-handle bar.
///
/// ### Usage
/// ```dart
/// await AppBottomSheet.show(
///   context: context,
///   builder: (ctx) => Column(children: [Text('Hello')]),
/// );
/// ```
///
/// The sheet pops with [Navigator.pop] exactly like a normal modal route.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
  });

  final Widget child;

  /// Inner padding. Defaults to `base` on all sides with extra top for handle.
  final EdgeInsetsGeometry? padding;

  /// Show the 40 px wide handle bar (default `true`).
  final bool showHandle;

  // ── Static show helper ───────────────────────────────────────────────────

  /// Show this sheet using a spring-physics route.
  ///
  /// [barrierDismissible] defaults to `true`.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool showHandle = true,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      _SpringBottomSheetRoute<T>(
        builder: (ctx) => AppBottomSheet(
          showHandle: showHandle,
          padding: padding,
          child: builder(ctx),
        ),
        barrierDismissible: barrierDismissible,
        isScrollControlled: isScrollControlled,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass surface colours matching GlassCardVariant.elevated
    final bgColor = isDark
        ? AppColors.darkGlassBackground          // rgba(28,25,23,0.60)
        : AppColors.lightGlassBackground;        // rgba(255,255,255,0.70)
    final borderColor = isDark
        ? AppColors.darkGlassBorder.withAlpha(0x14)   // 8 % border in dark
        : AppColors.lightGlassBorder.withAlpha(0x42); // 26 % border in light

    // Night glow (primary) matching elevated variant
    final boxShadows = [
      // Elevated shadow
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 0x52 : 0x30),
        blurRadius: isDark ? 40 : 20,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
      if (isDark)
        BoxShadow(
          color: AppColors.primaryNight.withAlpha(0x40),
          blurRadius: 20,
          spreadRadius: 0,
        ),
    ];

    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(
          AppSpacing.base,
          showHandle ? AppSpacing.lg : AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base + MediaQuery.of(context).viewInsets.bottom,
        );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXxl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: boxShadows,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const SizedBox(height: AppSpacing.sm),
                _HandleBar(isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
              ],
              Padding(padding: resolvedPadding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Handle bar ───────────────────────────────────────────────────────────────

class _HandleBar extends StatelessWidget {
  const _HandleBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkTextMuted.withAlpha(0x52)
            : AppColors.lightTextMuted.withAlpha(0x80),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  Spring-physics popup route
// ──────────────────────────────────────────────────────────────────────────────

/// A custom [PopupRoute] that drives its entrance with a [SpringSimulation],
/// giving the sheet a natural elastic slide-up feel without a hard-coded curve.
///
/// The spring properties come from [AppAnimations.defaultSpring]
/// (mass = 1, stiffness = 100, damping = 14 — slightly under-damped).
/// Reverse (close) uses a simple 200 ms ease-in so the dismiss feels quick.
class _SpringBottomSheetRoute<T> extends PopupRoute<T> {
  _SpringBottomSheetRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.isScrollControlled = false,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;

  @override
  final bool barrierDismissible;

  @override
  String? get barrierLabel => 'BottomSheet';

  @override
  Color get barrierColor => AppColors.scrim;

  // The spring entrance can take up to ~800 ms; the route's declared duration
  // is only used when reversing (closing) since we override didPush().
  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  @override
  Duration get reverseTransitionDuration =>
      AppAnimations.modalCloseDuration; // 200 ms

  // ── Drive entrance with spring physics ───────────────────────────────────

  @override
  TickerFuture didPush() {
    // Call super for bookkeeping (sets _animationProxy.parent, starts forward());
    // then immediately replace the simulation with spring physics so the
    // @mustCallSuper contract is satisfied while still getting natural overshoot.
    super.didPush();
    return controller!.animateWith(
      SpringSimulation(
        AppAnimations.defaultSpring, // mass=1, stiffness=100, damping=14
        0.0,  // start position
        1.0,  // end position
        0.0,  // initial velocity
      ),
    );
  }

  // ── Build transition (slide from bottom) ─────────────────────────────────

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Slide: bottom → resting position.
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(animation); // raw spring value — no extra curve wrapper

    // Subtle opacity fade for the barrier + content
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      ),
    );
  }
}
