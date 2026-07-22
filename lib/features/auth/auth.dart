import '../../core/constants.dart';
import '../../core/services.dart';
import '../../core/shared_widgets.dart';
import '../../theme/theme.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

abstract final class PremiumPageTransitions {
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration fast = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);

  static CustomTransitionPage<T> _fadeSlideUpImpl<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = standard,
    Duration reverseDuration = fast,
    double slideAmount = 0.05,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final slide =
            Tween<Offset>(
              begin: Offset(0, slideAmount),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  static CustomTransitionPage<T> _sharedAxisHImpl<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = standard,
    Duration reverseDuration = fast,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final slideBegin = Offset(isRtl ? -0.06 : 0.06, 0);

        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final slide = Tween<Offset>(begin: slideBegin, end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            );

        final secondarySlide =
            Tween<Offset>(
              begin: Offset.zero,
              end: Offset(isRtl ? 0.04 : -0.04, 0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInCubic,
              ),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: SlideTransition(position: secondarySlide, child: child),
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> fadeSlideUp<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = standard,
    Duration reverseDuration = fast,
    Offset begin = const Offset(0, 0.05),
  }) {
    return _fadeSlideUpImpl<T>(
      key: key,
      child: child,
      duration: duration,
      reverseDuration: reverseDuration,
      slideAmount: begin.dy,
    );
  }

  static CustomTransitionPage<T> fadeScale<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 340),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static CustomTransitionPage<T> sharedAxisHorizontal<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return _sharedAxisHImpl<T>(key: key, child: child);
  }

  static CustomTransitionPage<T> profileReveal<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> editProfileSlide<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: fast,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class PremiumAuthBackground extends StatelessWidget {
  final Widget child;

  const PremiumAuthBackground({
    super.key,
    required this.child,
    this.animateOrbs = false,
  });

  final bool animateOrbs;

  @override
  Widget build(BuildContext context) => child;
}

enum PremiumButtonState { idle, loading, success }

class PremiumActionButton extends StatefulWidget {
  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final PremiumButtonState state;
  final bool isOutlined;
  final bool expand;

  const PremiumActionButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.onPressed,
    this.state = PremiumButtonState.idle,
    this.isOutlined = false,
    this.expand = true,
  });

  @override
  State<PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<PremiumActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.onPressed != null && widget.state == PremiumButtonState.idle;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state == PremiumButtonState.loading;
    final isSuccess = widget.state == PremiumButtonState.success;
    final gradient = AppColors.primaryGradient;

    Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: isLoading
          ? Row(
              key: const ValueKey('loading'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumLoadingIndicator(
                  size: 20,
                  primaryColor: widget.isOutlined
                      ? AppColors.primary
                      : Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.loadingLabel ?? 'جاري التحقق...',
                  style: AppFonts.readex(
                    color: widget.isOutlined ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            )
          : isSuccess
          ? Row(
              key: const ValueKey('success'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'تم بنجاح',
                  style: AppFonts.readex(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            )
          : Text(
              widget.label,
              key: const ValueKey('label'),
              style: AppFonts.readex(
                color: widget.isOutlined ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
    );

    final button = GestureDetector(
      onTapDown: _enabled ? (_) => _pressController.forward() : null,
      onTapUp: _enabled
          ? (_) {
              _pressController.reverse();
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _enabled ? () => _pressController.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 28),
          decoration: BoxDecoration(
            gradient: !widget.isOutlined && _enabled
                ? gradient
                : isSuccess
                ? const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  )
                : null,
            color: widget.isOutlined
                ? Colors.transparent
                : (!_enabled && !isLoading && !isSuccess
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : null),
            borderRadius: BorderRadius.circular(28),
            border: widget.isOutlined
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  )
                : null,
            boxShadow:
                !widget.isOutlined && (isLoading || _enabled || isSuccess)
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Center(child: content),
        ),
      ),
    );

    return button;
  }
}

class PremiumLoadingIndicator extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const PremiumLoadingIndicator({
    super.key,
    this.size = 22,
    this.primaryColor = Colors.white,
    this.secondaryColor = AppColors.secondary,
  });

  @override
  State<PremiumLoadingIndicator> createState() =>
      _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _ArcPainter(
              rotation: _controller.value * 2 * math.pi,
              primary: widget.primaryColor,
              secondary: widget.secondaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double rotation;
  final Color primary;
  final Color secondary;

  _ArcPainter({
    required this.rotation,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [secondary, primary, secondary.withValues(alpha: 0.2)],
        transform: GradientRotation(rotation),
      ).createShader(rect);

    canvas.drawArc(rect, rotation, math.pi * 1.35, false, sweep);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

class PremiumVerificationCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int length;
  final String? Function(String?)? validator;

  const PremiumVerificationCodeInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.enabled = true,
    this.length = 6,
    this.validator,
  });

  @override
  State<PremiumVerificationCodeInput> createState() =>
      _PremiumVerificationCodeInputState();
}

class _PremiumVerificationCodeInputState
    extends State<PremiumVerificationCodeInput> {
  final FocusNode _focusNode = FocusNode();
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.controller.text;
    widget.controller.addListener(_syncFromController);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PremiumVerificationCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _value = widget.controller.text;
    }
  }

  void _syncFromController() {
    final next = widget.controller.text;
    if (next != _value) {
      setState(() => _value = next);
    }
  }

  void _onFocusChanged() => setState(() {});

  void _focusField() {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
  }

  void _handleChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;

    if (trimmed != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
        composing: TextRange.empty,
      );
    }

    setState(() => _value = trimmed);
    widget.onChanged?.call(trimmed);

    if (trimmed.length == widget.length) {
      HapticFeedback.lightImpact();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  int get _activeIndex {
    if (!_focusNode.hasFocus) {
      return _value.length >= widget.length ? widget.length - 1 : _value.length;
    }
    return _value.length.clamp(0, widget.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _focusField,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(widget.length, (index) {
                      final char = index < _value.length ? _value[index] : '';
                      final isFilled = char.isNotEmpty;
                      final isActive =
                          widget.enabled &&
                          _focusNode.hasFocus &&
                          index == _activeIndex;

                      return _DigitCell(
                        char: char,
                        isFilled: isFilled,
                        isActive: isActive,
                        hasError: hasError,
                        enabled: widget.enabled,
                      );
                    }),
                  ),
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        showCursor: false,
                        enableInteractiveSelection: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(widget.length),
                        ],
                        onChanged: (value) {
                          _handleChanged(value);
                          field.didChange(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? '',
                textAlign: TextAlign.center,
                style: AppFonts.readex(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DigitCell extends StatelessWidget {
  final String char;
  final bool isFilled;
  final bool isActive;
  final bool hasError;
  final bool enabled;

  const _DigitCell({
    required this.char,
    required this.isFilled,
    required this.isActive,
    required this.hasError,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = hasError
        ? AppColors.error.withValues(alpha: 0.65)
        : isActive
        ? AppColors.secondary
        : isFilled
        ? (isDark ? AppColors.secondary : AppColors.primary).withValues(
            alpha: 0.5,
          )
        : AppColors.border(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondary.withValues(alpha: 0.08)
            : isFilled
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: isFilled
              ? Text(
                  char,
                  key: ValueKey('digit-$char'),
                  style: AppFonts.readex(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                )
              : isActive
              ? _BlinkingCursor(key: const ValueKey('cursor'))
              : Text(
                  '•',
                  key: const ValueKey('placeholder'),
                  style: AppFonts.readex(
                    fontSize: 18,
                    color: AppColors.textSecondary(
                      context,
                    ).withValues(alpha: 0.25),
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({super.key});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.25,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class PremiumSectionSelector extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const PremiumSectionSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<PremiumSectionSelector> createState() => _PremiumSectionSelectorState();
}

class _PremiumSectionSelectorState extends State<PremiumSectionSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _expand;
  late final Animation<double> _fade;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _expand = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = CurvedAnimation(
      parent: _menuController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _toggleMenu() async {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      await _menuController.forward();
    } else {
      await _menuController.reverse();
    }
  }

  Future<void> _select(String section) async {
    if (!widget.enabled || section == widget.value) {
      await _toggleMenu();
      return;
    }
    HapticFeedback.lightImpact();
    widget.onChanged(section);
    await _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTrigger(
          value: widget.value,
          isOpen: _isOpen,
          enabled: widget.enabled,
          onTap: _toggleMenu,
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _expand,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _expand.value,
                child: Opacity(opacity: _fade.value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _SectionMenu(
                selected: widget.value,
                animation: _menuController,
                enabled: widget.enabled,
                onSelect: _select,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTrigger extends StatelessWidget {
  final String value;
  final bool isOpen;
  final bool enabled;
  final VoidCallback onTap;

  const _SectionTrigger({
    required this.value,
    required this.isOpen,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter = AppSections.letterFor(value);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.overlay(0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOpen
                  ? AppColors.secondary.withValues(alpha: 0.55)
                  : AppColors.border(context),
              width: isOpen ? 1.6 : 1,
            ),
            boxShadow: isOpen
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isOpen ? AppColors.primaryGradient : null,
                  color: isOpen
                      ? null
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.overlay(0.12)
                            : AppColors.primary.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: AppFonts.readex(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isOpen ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الشعبة',
                      style: AppFonts.readex(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppFonts.readex(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled
                      ? AppColors.icon(context)
                      : AppColors.textSecondary(context).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionMenu extends StatelessWidget {
  final String selected;
  final Animation<double> animation;
  final bool enabled;
  final ValueChanged<String> onSelect;

  const _SectionMenu({
    required this.selected,
    required this.animation,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface(context)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: List.generate(AppSections.all.length, (index) {
          final section = AppSections.all[index];
          final delay = index * 0.08;

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final slide = Curves.easeOutCubic.transform(
                ((animation.value - delay) / (1 - delay)).clamp(0.0, 1.0),
              );
              return Transform.translate(
                offset: Offset(0, (1 - slide) * 14),
                child: Opacity(opacity: slide, child: child),
              );
            },
            child: _SectionOptionTile(
              section: section,
              isSelected: section == selected,
              enabled: enabled,
              onTap: () => onSelect(section),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionOptionTile extends StatefulWidget {
  final String section;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _SectionOptionTile({
    required this.section,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SectionOptionTile> createState() => _SectionOptionTileState();
}

class _SectionOptionTileState extends State<_SectionOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final letter = AppSections.letterFor(widget.section);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected ? AppColors.primaryGradient : null,
              color: widget.isSelected
                  ? null
                  : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.overlay(0.08)
                        : AppColors.primary.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? Colors.transparent
                    : AppColors.border(context),
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.overlay(0.12)
                              : AppColors.primary.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: AppFonts.readex(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isSelected
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.section,
                    style: AppFonts.readex(
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.textPrimary(context),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: widget.isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: Colors.white,
                          size: 22,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('unselected'),
                          color: AppColors.textSecondary(
                            context,
                          ).withValues(alpha: 0.35),
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumSubjectSelector extends StatelessWidget {
  final Map<String, bool> selected;
  final ValueChanged<String> onToggle;
  final bool enabled;

  const PremiumSubjectSelector({
    super.key,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 360 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppSubjects.all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppLayout.itemGap,
            crossAxisSpacing: AppLayout.itemGap,
            childAspectRatio: crossAxisCount == 2 ? 1.65 : 2.6,
          ),
          itemBuilder: (context, index) {
            final subject = AppSubjects.all[index];
            return _SubjectCard(
              subject: subject,
              isSelected: selected[subject] ?? false,
              enabled: enabled,
              onTap: () {
                if (!enabled) return;
                HapticFeedback.selectionClick();
                onToggle(subject);
              },
            );
          },
        );
      },
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final String subject;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
    if (value) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(widget.subject);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.first.withValues(alpha: 0.06)
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.overlay(0.12)
                      : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? colors.first.withValues(alpha: 0.55)
                  : AppColors.border(context),
              width: widget.isSelected ? 1.8 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SubjectIcon(
                        subject: widget.subject,
                        size: widget.isSelected ? 40 : 44,
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: widget.isSelected
                            ? Container(
                                key: const ValueKey('check'),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.first.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : Container(
                                key: const ValueKey('empty'),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border(context),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: AppFonts.readex(
                      fontSize: widget.isSelected ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected
                          ? colors.first
                          : AppColors.textPrimary(context),
                      height: 1.25,
                    ),
                    child: Text(
                      widget.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_pressed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: colors.first.withValues(alpha: 0.06),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  PremiumButtonState _buttonState = PremiumButtonState.idle;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _buttonState = PremiumButtonState.loading);

    final started = DateTime.now();
    final auth = context.read<AuthService>();
    final error = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    final elapsed = DateTime.now().difference(started);
    const minLoading = Duration(milliseconds: 1200);
    if (elapsed < minLoading) {
      await Future.delayed(minLoading - elapsed);
    }

    if (!mounted) return;

    if (error != null) {
      setState(() => _buttonState = PremiumButtonState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    setState(() => _buttonState = PremiumButtonState.success);
    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    context.go(auth.getHomeRoute());
  }

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: const Text(
          'لأسباب أمنية، تُدار كلمات المرور من قِبل إدارة المعهد. يرجى التواصل مع الإدارة لإعادة تعيين كلمة مرورك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ambient.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = _buttonState != PremiumButtonState.idle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: _LoginAmbience(animation: _ambient, isDark: isDark),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 6, 26, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Image.asset(
                              AppIcons.logoMark,
                              height: 96,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.school_rounded,
                                size: 72,
                                color: AppColors.icon(context),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 520.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.88, 0.88),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 16),
                        Text(
                              'طريق المجد',
                              style: AppFonts.readex(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary(context),
                                letterSpacing: 0.5,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 90.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'تعلَّم • تطوّر • تفوّق',
                          textAlign: TextAlign.center,
                          style: AppFonts.readex(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                            letterSpacing: 0.4,
                          ),
                        ).animate().fadeIn(delay: 170.ms, duration: 520.ms),
                        _AuthGlobe(
                          animation: _ambient,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 220.ms, duration: 760.ms),
                        const SizedBox(height: 4),
                        _LoginForm(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              buttonState: _buttonState,
                              isBusy: isBusy,
                              onLogin: _login,
                              onForgot: _showForgotPassword,
                            )
                            .animate()
                            .fadeIn(delay: 280.ms, duration: 620.ms)
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final PremiumButtonState buttonState;
  final bool isBusy;
  final VoidCallback onLogin;
  final VoidCallback onForgot;

  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.buttonState,
    required this.isBusy,
    required this.onLogin,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: usernameController,
            enabled: !isBusy,
            textInputAction: TextInputAction.next,
            style: AppFonts.readex(fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              labelText: 'اسم المستخدم',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم المستخدم';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordTextField(
            controller: passwordController,
            labelText: 'كلمة المرور',
            enabled: !isBusy,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: isBusy ? null : onForgot,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'نسيت كلمة المرور؟',
                style: AppFonts.readex(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.icon(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PremiumActionButton(
            label: 'دخول',
            loadingLabel: 'جاري التحقق...',
            state: buttonState,
            onPressed: isBusy ? null : onLogin,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'للحصول على حساب، تواصل مع إدارة المعهد',
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginAmbience extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;

  const _LoginAmbience({required this.animation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.74),
                radius: 1.1,
                colors: [
                  (isDark ? AppColors.primaryBright : AppColors.primary)
                      .withValues(alpha: isDark ? 0.17 : 0.07),
                  Colors.transparent,
                ],
                stops: const [0, 0.7],
              ),
            ),
          ),
          if (isDark)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, _) =>
                    CustomPaint(painter: _StarFieldPainter(animation.value)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double t;

  _StarFieldPainter(this.t);

  static final List<Offset> _stars = _generate();

  static List<Offset> _generate() {
    final rnd = math.Random(7);
    return List.generate(
      46,
      (_) => Offset(rnd.nextDouble(), rnd.nextDouble()),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      if (s.dy > 0.6) continue;
      final tw = 0.5 + 0.5 * math.sin(t * 2 * math.pi + i * 0.7);
      final radius = 0.6 + (i % 3) * 0.5;
      p.color = Colors.white.withValues(alpha: 0.05 + 0.22 * tw);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        radius,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _AuthGlobe extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;

  const _AuthGlobe({required this.animation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 178,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, _) =>
              CustomPaint(painter: _GlobePainter(animation.value, isDark)),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  final double t;
  final bool isDark;

  const _GlobePainter(this.t, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.92;
    final center = Offset(w / 2, r + h * 0.26);
    final rect = Rect.fromCircle(center: center, radius: r);

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.62),
        radius: 0.95,
        colors: isDark
            ? const [Color(0xFF1C4E88), Color(0xFF102A4E), Color(0xFF0A1830)]
            : const [Color(0xFFE6F1FD), Color(0xFFCBDFF8), Color(0xFFB7D3F4)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, r, sphere);
    _drawDots(canvas, center, r);
    canvas.restore();

    final rimGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFF6FC1F8) : const Color(0xFF2E6FE8))
          .withValues(alpha: isDark ? 0.85 : 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawArc(rect, math.pi * 1.22, math.pi * 0.56, false, rimGlow);

    final rimCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFFCDE8FF) : const Color(0xFF3B82F6))
          .withValues(alpha: isDark ? 0.85 : 0.5);
    canvas.drawArc(rect, math.pi * 1.22, math.pi * 0.56, false, rimCore);

    _drawConnections(canvas, center, r);
  }

  void _drawDots(Canvas canvas, Offset center, double r) {
    const latN = 14;
    const lonN = 30;
    final rot = t * 2 * math.pi;
    final base = isDark ? const Color(0xFF4C93EE) : const Color(0xFF2E6FE8);
    final p = Paint();
    for (int i = 1; i < latN; i++) {
      final lat = (i / latN) * math.pi - math.pi / 2;
      final cl = math.cos(lat);
      final sl = math.sin(lat);
      for (int j = 0; j < lonN; j++) {
        final lon = (j / lonN) * 2 * math.pi + rot;
        final z = cl * math.sin(lon);
        if (z <= 0.03) continue;
        final x = cl * math.cos(lon);
        final px = center.dx + x * r;
        final py = center.dy - sl * r;
        final a = (0.12 + z * 0.55) * (isDark ? 1.0 : 0.65);
        p.color = base.withValues(alpha: a.clamp(0.0, 0.85));
        canvas.drawCircle(Offset(px, py), 1.1 + z * 1.3, p);
      }
    }
  }

  List<Offset> _nodes(Offset center, double r) {
    const angles = [1.34, 1.42, 1.5, 1.58, 1.66];
    return [
      for (final a in angles)
        Offset(
          center.dx + math.cos(a * math.pi) * r,
          center.dy + math.sin(a * math.pi) * r,
        ),
    ];
  }

  void _drawConnections(Canvas canvas, Offset center, double r) {
    final nodes = _nodes(center, r);
    final arcColor = isDark
        ? const Color(0xFF6FC1F8)
        : const Color(0xFF3B82F6);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = arcColor.withValues(alpha: isDark ? 0.45 : 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = arcColor.withValues(alpha: isDark ? 0.7 : 0.45);

    const pairs = [
      [0, 2],
      [2, 4],
      [1, 3],
      [0, 3],
    ];
    for (final pr in pairs) {
      final a = nodes[pr[0]];
      final b = nodes[pr[1]];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final lift = (a - b).distance * 0.42;
      final ctrl = Offset(mid.dx, mid.dy - lift);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }

    for (int i = 0; i < nodes.length; i++) {
      final pulse = 0.55 + 0.45 * math.sin(t * 2 * math.pi * 1.4 + i * 1.3);
      final n = nodes[i];
      final radius = 9 + 6 * pulse;
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            arcColor.withValues(alpha: (isDark ? 0.5 : 0.34) * pulse),
            arcColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: n, radius: radius));
      canvas.drawCircle(n, radius, halo);
      final core = Paint()
        ..color = (isDark ? const Color(0xFFEAF5FF) : const Color(0xFF2E6FE8))
            .withValues(alpha: 0.92);
      canvas.drawCircle(n, 2.4, core);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}
