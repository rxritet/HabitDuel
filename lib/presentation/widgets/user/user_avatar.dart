import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Enumerations
// ──────────────────────────────────────────────────────────────────────────────

/// Заранее заданные размеры для [UserAvatar].
enum AvatarSize {
  /// 32 пт — списки, пузыри, компактные строки.
  small,

  /// 48 пт — стандартные элементы списка.
  medium,

  /// 64 пт — заголовки профиля, карточки дуэлей.
  large,

  /// 96 пт — экран профиля, оверлей победы.
  extraLarge,
}

/// Статус онлайн/активности, определяющий стиль рамки.
enum AvatarStatus {
  /// Без рамки — нейтральное состояние.
  none,

  /// Градиентное кольцо primary — пользователь активен или участвует в дуэли.
  active,

  /// Кольцо tertiary (зелёное) — этот пользователь победил в дуэли.
  winner,

  /// Плоское серое кольцо — пользователь оффлайн.
  offline,
}

// ──────────────────────────────────────────────────────────────────────────────
//  Size helpers
// ──────────────────────────────────────────────────────────────────────────────

extension _AvatarSizeValue on AvatarSize {
  double get diameter => switch (this) {
    AvatarSize.small      => AppSpacing.avatarSm, // 32
    AvatarSize.medium     => AppSpacing.avatarMd, // 48
    AvatarSize.large      => AppSpacing.avatarLg, // 64
    AvatarSize.extraLarge => 96.0,
  };

  /// Толщина границы кольца зависит от размера аватара.
  double get borderWidth => switch (this) {
    AvatarSize.small      => 1.5,
    AvatarSize.medium     => 2.0,
    AvatarSize.large      => 2.5,
    AvatarSize.extraLarge => 3.0,
  };

  /// Зазор между градиентным кольцом и изображением.
  double get ringGap => switch (this) {
    AvatarSize.small      => 1.5,
    AvatarSize.medium     => 2.0,
    AvatarSize.large      => 2.5,
    AvatarSize.extraLarge => 3.0,
  };

  /// Размер шрифта для инициалов.
  double get initialsFontSize => switch (this) {
    AvatarSize.small      => 12.0,
    AvatarSize.medium     => 16.0,
    AvatarSize.large      => 22.0,
    AvatarSize.extraLarge => 34.0,
  };

  /// Диаметр точки статуса.
  double get dotSize => switch (this) {
    AvatarSize.small      => 8.0,
    AvatarSize.medium     => 10.0,
    AvatarSize.large      => 12.0,
    AvatarSize.extraLarge => 16.0,
  };
}

// ──────────────────────────────────────────────────────────────────────────────
//  UserAvatar
// ──────────────────────────────────────────────────────────────────────────────

/// Круглый аватар с градиентным статусным кольцом и резервным отображением инициалов.
///
/// ### Размеры
/// Четыре предустановленных через [AvatarSize]: `small` (32), `medium` (48), `large` (64), `extraLarge` (96).
///
/// ### Границы статуса
/// | [AvatarStatus]  | Граница                      |
/// |-----------------|-----------------------------|
/// | `none`          | прозрачная (без рамки)     |
/// | `active`        | градиент primary             |
/// | `winner`        | градиент tertiary/success    |
/// | `offline`       | плоское серое кольцо       |
///
/// ### Изображение / резерв
/// Укажите [imageUrl] для сетевого изображения. При отсутствии — цветной круг с [initials].
///
/// ```dart
/// UserAvatar(
///   size: AvatarSize.large,
///   status: AvatarStatus.active,
///   imageUrl: user.avatarUrl,
///   name: user.displayName,
/// )
/// ```
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = AvatarSize.medium,
    this.status = AvatarStatus.none,
    this.imageUrl,
    this.name,
    this.initials,
    this.onTap,
    this.showStatusDot = false,
  });

  /// Управляет общим диаметром аватара.
  final AvatarSize size;

  /// Стиль границы статуса.
  final AvatarStatus status;

  /// URL сетевого изображения. При отсутствии — инициалы.
  final String? imageUrl;

  /// Отображаемое имя — используется для вывода инициалов.
  final String? name;

  /// Явные инициалы (макс 2 символа).
  final String? initials;

  /// Опциональный колбэк нажатия.
  final VoidCallback? onTap;

  /// Если `true` — небольшая точка статуса в правом нижнем углу.
  final bool showStatusDot;

  // ── Формирование инициалов ─────────────────────────────────────────────────

  String _resolveInitials() {
    final src = initials ?? name ?? '';
    if (src.isEmpty) return '?';
    final parts = src.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return src.substring(0, src.length.clamp(1, 2)).toUpperCase();
  }

  // ── Цвет фона инициалов — детерминированный хеш ─────────────────────────

  Color _initialsBackground(String text) {
    const palette = [
      Color(0xFF0EA5E9), // ocean
      Color(0xFF8B5CF6), // violet
      Color(0xFFF43F5E), // coral
      Color(0xFF10B981), // mint
      Color(0xFFF59E0B), // amber
      Color(0xFF6366F1), // indigo
      Color(0xFFEC4899), // pink
      Color(0xFF14B8A6), // teal
    ];
    final idx = text.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = size.diameter;

    Widget avatar = _AvatarCore(
      diameter: d,
      size: size,
      status: status,
      imageUrl: imageUrl,
      initials: _resolveInitials(),
      initialsBackground: _initialsBackground(_resolveInitials()),
      isDark: isDark,
    );

    // Накладка индикатора статуса
    if (showStatusDot && status != AvatarStatus.none) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: _StatusDot(status: status, size: size.dotSize, isDark: isDark),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _AvatarCore
// ──────────────────────────────────────────────────────────────────────────────

class _AvatarCore extends StatelessWidget {
  const _AvatarCore({
    required this.diameter,
    required this.size,
    required this.status,
    required this.imageUrl,
    required this.initials,
    required this.initialsBackground,
    required this.isDark,
  });

  final double diameter;
  final AvatarSize size;
  final AvatarStatus status;
  final String? imageUrl;
  final String initials;
  final Color initialsBackground;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasBorder = status != AvatarStatus.none;
    final ringGap = hasBorder ? size.ringGap : 0.0;
    final borderWidth = hasBorder ? size.borderWidth : 0.0;
    // Inner image diameter shrinks to leave room for ring + gap
    final innerD = diameter - (borderWidth + ringGap) * 2;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: hasBorder
            ? _RingPainter(
                status: status,
                isDark: isDark,
                borderWidth: borderWidth,
              )
            : null,
        child: Center(
          child: _ImageCircle(
            diameter: innerD,
            imageUrl: imageUrl,
            initials: initials,
            initialsBackground: initialsBackground,
            fontSize: size.initialsFontSize,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _ImageCircle
// ──────────────────────────────────────────────────────────────────────────────

class _ImageCircle extends StatelessWidget {
  const _ImageCircle({
    required this.diameter,
    required this.imageUrl,
    required this.initials,
    required this.initialsBackground,
    required this.fontSize,
    required this.isDark,
  });

  final double diameter;
  final String? imageUrl;
  final String initials;
  final Color initialsBackground;
  final double fontSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _InitialsCircle(
                  initials: initials,
                  background: initialsBackground,
                  fontSize: fontSize,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _shimmerCircle(isDark);
                },
              )
            : _InitialsCircle(
                initials: initials,
                background: initialsBackground,
                fontSize: fontSize,
              ),
      ),
    );
  }

  Widget _shimmerCircle(bool isDark) => Container(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  _InitialsCircle
// ──────────────────────────────────────────────────────────────────────────────

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initials,
    required this.background,
    required this.fontSize,
  });

  final String initials;
  final Color background;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.button.copyWith(
          fontSize: fontSize,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _RingPainter
// ──────────────────────────────────────────────────────────────────────────────

/// Рисует круговую градиентную / сплошную рамку аватара.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.status,
    required this.isDark,
    required this.borderWidth,
  });

  final AvatarStatus status;
  final bool isDark;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - borderWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;

    switch (status) {
      case AvatarStatus.active:
        final gradient = isDark ? AppGradients.primaryNight : AppGradients.primaryDay;
        paint.shader = gradient.createShader(rect);
      case AvatarStatus.winner:
        paint.shader = AppGradients.success.createShader(rect);
      case AvatarStatus.offline:
        paint.color = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      case AvatarStatus.none:
        return; // nothing to paint
    }

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.status != status ||
      old.isDark != isDark ||
      old.borderWidth != borderWidth;
}

// ──────────────────────────────────────────────────────────────────────────────
//  _StatusDot
// ──────────────────────────────────────────────────────────────────────────────

/// Небольшая точка в правом нижнем углу для отображения онлайн-статуса.
class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.status,
    required this.size,
    required this.isDark,
  });

  final AvatarStatus status;
  final double size;
  final bool isDark;

  Color _dotColor() => switch (status) {
    AvatarStatus.active   => isDark ? AppColors.primaryNight : AppColors.primary,
    AvatarStatus.winner   => isDark ? AppColors.tertiaryNight : AppColors.tertiary,
    AvatarStatus.offline  => isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
    AvatarStatus.none     => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _dotColor(),
        border: Border.all(color: bg, width: 1.5),
      ),
    );
  }
}
