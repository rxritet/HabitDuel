import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Enumerations
// ──────────────────────────────────────────────────────────────────────────────

/// Controls the manual validation state of [HabitInput].
enum HabitInputState {
  /// No validation feedback — default idle state.
  idle,

  /// Field value is acceptable — shows a success icon.
  success,

  /// Non-blocking advisory — amber border + warning icon.
  warning,

  /// Hard validation error — red border + error icon.
  error,
}

// ──────────────────────────────────────────────────────────────────────────────
//  HabitInput
// ──────────────────────────────────────────────────────────────────────────────

/// Premium Glass design-system text input.
///
/// ### Visual behaviour
/// - **Idle**: surface-coloured fill, warm-grey border, no shadow.
/// - **Focused**: border animates to primary colour; a soft primary-tinted
///   glow shadow fades in (250 ms `easeOut`).
/// - **Warning**: amber border + [Icons.warning_amber_rounded] suffix icon.
/// - **Error**: red border + [Icons.error_rounded] suffix icon; helper text
///   rendered below in error colour.
/// - **Success**: green border + [Icons.check_circle_rounded] suffix icon.
///
/// ### Parameters
/// ```dart
/// HabitInput(
///   label: 'Habit name',
///   hint: 'e.g. Meditate 10 min',
///   errorText: formState.habitNameError,
///   inputState: formState.habitNameState,
///   onChanged: (v) => ref.read(provider.notifier).setName(v),
/// )
/// ```
class HabitInput extends StatefulWidget {
  const HabitInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.inputState = HabitInputState.idle,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.autofocus = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String? hint;

  /// Shown below the field in neutral colour when [inputState] is not error.
  final String? helperText;

  /// Shown below the field in error colour; also forces [inputState] to
  /// [HabitInputState.error] regardless of the explicit [inputState] value.
  final String? errorText;

  final TextEditingController? controller;

  /// An external [FocusNode]. If `null` the widget manages its own.
  final FocusNode? focusNode;

  /// Explicit validation state. Ignored when [errorText] is non-null
  /// (error state takes precedence).
  final HabitInputState inputState;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  /// Leading icon shown inside the field. Tinted to primary when focused.
  final Widget? prefixIcon;

  final bool autofocus;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  @override
  State<HabitInput> createState() => _HabitInputState();
}

class _HabitInputState extends State<HabitInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  late AnimationController _animCtrl;
  late Animation<double> _focusAnim;  // 0.0 = unfocused, 1.0 = focused

  bool _focused = false;
  bool _obscured = false; // for password toggle

  @override
  void initState() {
    super.initState();

    _obscured = widget.obscureText;

    // Focus node
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);

    // Animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _focusAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    focused ? _animCtrl.forward() : _animCtrl.reverse();
  }

  // ── Effective state ──────────────────────────────────────────────────────

  /// `errorText` always overrides explicit `inputState`.
  HabitInputState get _effectiveState =>
      (widget.errorText?.isNotEmpty == true)
          ? HabitInputState.error
          : widget.inputState;

  // ── Resolved colours ─────────────────────────────────────────────────────

  Color _primaryColor(bool isDark) =>
      isDark ? AppColors.primaryNight : AppColors.primary;

  Color _borderIdle(bool isDark) =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;

  Color _borderForState(bool isDark) {
    return switch (_effectiveState) {
      HabitInputState.error   => AppColors.error,
      HabitInputState.warning => isDark ? AppColors.warningNight : AppColors.warning,
      HabitInputState.success => isDark ? AppColors.tertiaryNight : AppColors.tertiary,
      HabitInputState.idle    => _primaryColor(isDark),
    };
  }

  Color _surfaceColor(bool isDark) =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;

  Color _textColor(bool isDark) =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color _hintColor(bool isDark) =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Color _labelColor(bool isDark) =>
      _focused
          ? _primaryColor(isDark)
          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

  // ── Suffix icon ──────────────────────────────────────────────────────────

  Widget? _buildSuffixIcon(bool isDark) {
    if (widget.obscureText) {
      return GestureDetector(
        onTap: () => setState(() => _obscured = !_obscured),
        child: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: AppSpacing.iconSm,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      );
    }

    return switch (_effectiveState) {
      HabitInputState.error => Icon(
          Icons.error_rounded,
          size: AppSpacing.iconSm,
          color: AppColors.error,
        ),
      HabitInputState.warning => Icon(
          Icons.warning_amber_rounded,
          size: AppSpacing.iconSm,
          color: isDark ? AppColors.warningNight : AppColors.warning,
        ),
      HabitInputState.success => Icon(
          Icons.check_circle_rounded,
          size: AppSpacing.iconSm,
          color: isDark ? AppColors.tertiaryNight : AppColors.tertiary,
        ),
      HabitInputState.idle => null,
    };
  }

  // ── Glow shadow ──────────────────────────────────────────────────────────

  List<BoxShadow> _buildShadows(bool isDark, double t) {
    if (_effectiveState != HabitInputState.idle || t == 0.0) return const [];

    final primary = _primaryColor(isDark);
    // Glow fades in with focus animation (t: 0→1)
    return [
      BoxShadow(
        color: primary.withAlpha((0x26 * t).round()), // max ~15 % opacity
        blurRadius: 8 * t,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: primary.withAlpha((0x14 * t).round()), // max ~8 % opacity
        blurRadius: 16 * t,
        spreadRadius: 0,
      ),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (context, _) {
        final t = _focusAnim.value;

        // Interpolate border colour between idle and active
        final idleBorder = _borderIdle(isDark);
        final activeBorder = _borderForState(isDark);
        final borderColor = (_effectiveState == HabitInputState.idle && !_focused)
            ? idleBorder
            : Color.lerp(idleBorder, activeBorder, t) ?? activeBorder;

        final borderWidth = 1.0 + 0.5 * t; // 1.0 → 1.5 on focus
        final shadows = _buildShadows(isDark, t);
        final suffixIcon = _buildSuffixIcon(isDark);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Label ───────────────────────────────────────────────────────
            if (widget.label != null) ...[
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: AppTypography.caption.copyWith(
                  color: _effectiveState == HabitInputState.error
                      ? AppColors.error
                      : _labelColor(isDark),
                ),
                child: Text(widget.label!),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            // ── Input container with animated glow ──────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? _surfaceColor(isDark)
                    : _surfaceColor(isDark).withAlpha(0x99),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: shadows,
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                obscureText: widget.obscureText ? _obscured : false,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                autofocus: widget.autofocus,
                autocorrect: widget.autocorrect,
                textCapitalization: widget.textCapitalization,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                style: AppTypography.input.copyWith(color: _textColor(isDark)),
                cursorColor: _primaryColor(isDark),
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTypography.input.copyWith(
                    color: _hintColor(isDark),
                  ),
                  // Strip all default decoration — we paint our own container
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, // 16 px
                    vertical: AppSpacing.base,   // 16 px
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.base),
                          child: IconTheme(
                            data: IconThemeData(
                              color: _focused
                                  ? _primaryColor(isDark)
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                              size: AppSpacing.iconSm,
                            ),
                            child: widget.prefixIcon!,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: AppSpacing.iconSm + AppSpacing.base + AppSpacing.sm,
                    minHeight: 0,
                  ),
                  suffixIcon: suffixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.base),
                          child: suffixIcon,
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: AppSpacing.iconSm + AppSpacing.base + AppSpacing.sm,
                    minHeight: 0,
                  ),
                  counterText: '', // hide maxLength counter
                  isDense: true,
                  isCollapsed: false,
                ),
              ),
            ),

            // ── Helper / error text ─────────────────────────────────────────
            _buildHelperText(isDark),
          ],
        );
      },
    );
  }

  Widget _buildHelperText(bool isDark) {
    final errorText = widget.errorText;
    final helperText = widget.helperText;

    if (errorText != null && errorText.isNotEmpty) {
      return _HelperLine(
        text: errorText,
        color: AppColors.error,
        icon: Icons.error_outline_rounded,
      );
    }

    if (helperText != null && helperText.isNotEmpty) {
      return _HelperLine(
        text: helperText,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      );
    }

    return const SizedBox.shrink();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  _HelperLine
// ──────────────────────────────────────────────────────────────────────────────

class _HelperLine extends StatelessWidget {
  const _HelperLine({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
