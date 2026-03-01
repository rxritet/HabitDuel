import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Enumerations
// ──────────────────────────────────────────────────────────────────────────────

/// Вариант визуальной глубины для [GlassCard].
///
/// | Вариант  | Blur | Тень          | Opacity |
/// |-----------|------|-----------|---------|
/// | `default` | 20   | card      | 1.0     |
/// | `elevated`| 20   | elevated  | 1.0     |
/// | `flat`    | 12   | нет        | 0.8     |
enum GlassCardVariant {
  /// Стандартная стеклянная карточка — тень уровня card, полная непрозрачность.
  defaultCard,

  /// Приподнятая карточка — глубокая тень + опциональное ночное свечение.
  elevated,

  /// Плоская стеклянная панель — без тени, меньше блюр, слегка прозрачнее.
  flat,
}

/// Опциональный цвет внешнего свечения — только в тёмном режиме.
///
/// Соответствует токенам `glow-*` из DESIGN.md §2.6.
enum GlassGlowType {
  none,

  /// `0 0 20px rgba(56,189,248,0.25)` — синее неба (primary).
  primary,

  /// `0 0 20px rgba(251,113,133,0.25)` — розовый (secondary).
  secondary,

  /// `0 0 20px rgba(52,211,153,0.25)` — зелёный (success).
  success,
}

// ──────────────────────────────────────────────────────────────────────────────
//  GlassCard
// ──────────────────────────────────────────────────────────────────────────────

/// Компонент стеклянной карточки Premium Glass.
///
/// Отрисовывает поверхность матового стекла через [BackdropFilter],
/// адаптируя все визуальные свойства под текущую яркость темы.
///
/// ### Варианты
/// - [GlassCardVariant.defaultCard] — стандартная глубина.
/// - [GlassCardVariant.elevated]   — приподнятая, с глубокой тенью и свечением.
/// - [GlassCardVariant.flat]       — плоская, без тени и рамки.
///
/// ### Анимация мерцания
/// Установите [shimmer] = `true` для диагонального прохода градиента.
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

  /// Содержимое карточки.
  final Widget child;

  /// Вариант тени/глубины. По умолчанию [GlassCardVariant.defaultCard].
  final GlassCardVariant variant;

  /// Цвет внешнего свечения в тёмном режиме.
  /// Не активен в светлом режиме или при [GlassCardVariant.flat].
  final GlassGlowType glow;

  /// Если `true`, диагональный градиент медленно проходит по поверхности.
  final bool shimmer;

  /// Радиус скругления. По умолчанию [AppSpacing.radiusLg] (16 пт).
  final BorderRadius? borderRadius;

  /// Внутренние отступы. По умолчанию [AppSpacing.base] (все 4 стороны).
  final EdgeInsetsGeometry? padding;

  /// Внешние отступы.
  final EdgeInsetsGeometry? margin;

  /// Опциональная фиксированная ширина.
  final double? width;

  /// Опциональная фиксированная высота.
  final double? height;

  /// Колбэк нажатия. При наличии — карточка масштабируется при нажатии.
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  // ── Контроллер мерцания ─────────────────────────────────────────────────
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  // ── Состояние нажатия ───────────────────────────────────────────────────
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

  // ── Вспомогательные методы ──────────────────────────────────────────────

  double get _blurSigma => switch (widget.variant) {
    GlassCardVariant.flat => 12.0,
    _ => 20.0,
  };

  Color _resolveBackground(bool isDark) {
    final baseOpacity = widget.variant == GlassCardVariant.flat ? 0.85 : 1.0;

    if (isDark) {
      // Тёмная: серый уголь 60 % → flat: чуть менее непрозрачный
      return Color.fromARGB(
        (0x99 * baseOpacity).round(), // 0x99 = 153 ≈ 60 %
        0x1C,
        0x19,
        0x17,
      );
    } else {
      // Светлая: белый 70 % → flat: чуть прозрачнее
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
      // Тёмная: белый 5 %; elevated — 8 % для чёткости
      final alpha = widget.variant == GlassCardVariant.elevated ? 0x14 : 0x0D;
      return Color.fromARGB(alpha, 0xFF, 0xFF, 0xFF);
    } else {
      // Светлая: белый 20 %; elevated — 26 % для чёткости
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
        // ── Базовая тень ────────────────────────────────────────────────
        ..._darkBaseShadow,
        // ── Ночное свечение ─────────────────────────────────────────────
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

  // ── Сборка ────────────────────────────────────────────────────────────────

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

    // Оборачиваем в margin если задан
    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    // Интерактивная анимация нажатия
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

/// Внутренний виджет медленно движущегося диагонального градиента.
///
/// Значение [animation] (0.0 → 1.0 → 0.0, цикл) управляет выравнивание
/// [LinearGradient.begin]/[LinearGradient.end], создавая плавный проход слева-сверху направо-вниз.
class _ShimmerOverlay extends AnimatedWidget {
  const _ShimmerOverlay({required Animation<double> animation})
    : super(listenable: animation);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _animation.value; // 0.0 → 1.0

    // Смещаем начало/конец градиента по диагонали по мере t
    final begin = Alignment(-1.5 + t * 3.0, -1.5 + t * 1.5);
    final end = Alignment(-0.5 + t * 3.0, -0.5 + t * 1.5);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: const [
              Color(0x00FFFFFF), //  0 % белого — ведущий край
              Color(0x0CFFFFFF), //  5 % белого — пик мерцания
              Color(0x1AFFFFFF), // 10 % белого — ядро свечения
              Color(0x0CFFFFFF), //  5 % белого — затухание
              Color(0x00FFFFFF), //  0 % белого — ведомый край
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
