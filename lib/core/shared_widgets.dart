import 'core.dart';
import '../theme/theme.dart';
import '../theme/motion.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.showBorder = true,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final card = AnimatedContainer(
      duration: AppTheme.mediumAnimation,
      curve: Curves.easeInOut,
      margin: margin ?? const EdgeInsets.only(bottom: AppLayout.cardGap),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: AppColors.border(context))
            : null,
        boxShadow: shadows ?? AppShadows.of(brightness),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return PressableScale(onTap: onTap, child: card);
  }
}

class CircularLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const CircularLogo({super.key, this.size = 120, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          AppIcons.logo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(
            Icons.school_rounded,
            size: size * 0.45,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class SubjectIcon extends StatelessWidget {
  final String subject;
  final double size;
  final bool showBorder;
  final bool showShadow;

  const SubjectIcon({
    super.key,
    required this.subject,
    this.size = 56,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(subject);
    final asset = AppSubjects.bannerAssetFor(subject);
    final borderWidth = (size * 0.045).clamp(1.5, 3.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: isDark ? AppColors.borderDark : Colors.white,
                  width: borderWidth,
                )
              : null,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.22),
                    blurRadius: size * 0.2,
                    offset: Offset(0, size * 0.07),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: asset != null
              ? Image.asset(
                  asset,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _SubjectFallback(
                        subject: subject,
                        size: size,
                        colors: colors,
                      ),
                )
              : _SubjectFallback(subject: subject, size: size, colors: colors),
        ),
      ),
    );
  }
}

class _SubjectFallback extends StatelessWidget {
  final String subject;
  final double size;
  final List<Color> colors;

  const _SubjectFallback({
    required this.subject,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        AppSubjects.iconFor(subject),
        color: Colors.white,
        size: size * 0.44,
      ),
    );
  }
}

class SubjectChip extends StatelessWidget {
  final String subject;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const SubjectChip({
    super.key,
    required this.subject,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = !compact && AppSubjects.hasBanner(subject);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.standardCurve,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : (hasIcon ? 10 : 16),
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface(context),
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon) ...[
              SubjectIcon(
                subject: subject,
                size: 24,
                showShadow: false,
                showBorder: true,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              subject,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: compact ? 12 : 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedPressButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;

  const AnimatedPressButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = true,
    this.isOutlined = false,
    this.padding,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.instant);
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryGradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.primaryGradient;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final disabledBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.surfaceAltLight;
    final textColor = widget.isOutlined
        ? (enabled ? primaryColor : AppColors.textSecondary(context))
        : (enabled ? Colors.white : AppColors.textSecondary(context));

    return GestureDetector(
      onTapDown: enabled ? (_) => _controller.forward() : null,
      onTapUp: enabled
          ? (_) {
              _controller.reverse();
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
          decoration: BoxDecoration(
            gradient: widget.isPrimary && !widget.isOutlined && enabled
                ? primaryGradient
                : null,
            color: widget.isOutlined
                ? Colors.transparent
                : (!widget.isPrimary || !enabled ? disabledBg : null),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: widget.isOutlined
                ? Border.all(
                    color: enabled ? primaryColor : AppColors.border(context),
                    width: 1.6,
                  )
                : null,
            boxShadow: widget.isPrimary && enabled && !widget.isOutlined
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.25 : 0.3,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? Function(String?)? validator;
  final IconData prefixIcon;
  final bool enabled;
  final ValueChanged<bool>? onVisibilityChanged;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'كلمة المرور',
    this.validator,
    this.prefixIcon = Icons.lock_outline_rounded,
    this.enabled = true,
    this.onVisibilityChanged,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  void _toggleObscure() {
    final willBeRevealed = _obscure;
    setState(() => _obscure = !_obscure);
    widget.onVisibilityChanged?.call(willBeRevealed);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: Icon(widget.prefixIcon, color: AppColors.icon(context)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.icon(context),
          ),
          onPressed: _toggleObscure,
          tooltip: _obscure ? 'إظهار' : 'إخفاء',
        ),
      ),
    );
  }
}

class AppAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final double? opacity;
  final BoxFit fit;
  final Color? tintColor;

  const AppAssetIcon({
    super.key,
    required this.assetPath,
    required this.size,
    this.opacity,
    this.fit = BoxFit.contain,
    this.tintColor,
  });

  AppAssetIcon.kind({
    super.key,
    required AppIconKind kind,
    required this.size,
    this.opacity,
    this.fit = BoxFit.contain,
    this.tintColor,
  }) : assetPath = kind.assetPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTint =
        tintColor ?? (isDark ? AppColors.iconColorDark : AppColors.iconColor);

    Widget image;
    final ext = assetPath.split('.').last.toLowerCase();

    if (ext == 'svg') {
      image = SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        colorFilter: ColorFilter.mode(effectiveTint, BlendMode.srcIn),
      );
    } else {
      image = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.medium,
        color: effectiveTint,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) => Icon(
          Icons.image_not_supported_outlined,
          size: size * 0.75,
          color: effectiveTint,
        ),
      );
    }

    if (opacity != null && opacity! < 1) {
      image = Opacity(opacity: opacity!, child: image);
    }

    return image;
  }
}

class AppNavIcon extends StatelessWidget {
  final AppIconKind kind;
  final bool selected;
  final double size;

  const AppNavIcon({
    super.key,
    required this.kind,
    this.selected = false,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.accent : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.iconColorDark.withValues(alpha: 0.55)
        : AppColors.iconColor.withValues(alpha: 0.45);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: AppMotion.standard,
      curve: AppMotion.overshoot,
      builder: (context, t, _) {
        final lift = -3.0 * t;
        final scale = 1.0 + 0.12 * t;
        final tintColor = Color.lerp(unselectedColor, selectedColor, t)!;

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: scale,
            child: AppAssetIcon(
              assetPath: kind.assetPath,
              size: size,
              tintColor: tintColor,
            ),
          ),
        );
      },
    );
  }
}

class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({super.key});

  static const LinearGradient _light = LinearGradient(
    colors: [Color(0xFFF7FAFE), Color(0xFFF1F6FC), Color(0xFFEAF1FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient _dark = LinearGradient(
    colors: [Color(0xFF0C1424), Color(0xFF0A101C), Color(0xFF080D17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: AppMotion.deliberate,
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(gradient: isDark ? _dark : _light),
      ),
    );
  }
}

class AppBackgroundLayer extends StatelessWidget {
  final Widget? child;

  const AppBackgroundLayer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [const ThemeBackdrop(), ?child],
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptics;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.enableHaptics = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              if (widget.enableHaptics) {
                HapticFeedback.lightImpact();
              }
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.instant,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: AppMotion.instant,
          opacity: _pressed ? 0.92 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final String title;
  final bool showLogo;
  final List<Widget>? actions;
  final double? height;
  final bool menuOpen;

  const AppTopBar({
    super.key,
    this.onMenuTap,
    this.onBackTap,
    required this.title,
    this.showLogo = true,
    this.actions,
    this.height,
    this.menuOpen = false,
  });

  static const double _sideSlotWidth = 52;

  @override
  Size get preferredSize => Size.fromHeight(height ?? AppLayout.appBarHeight);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuIconController;

  @override
  void initState() {
    super.initState();
    _menuIconController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    if (widget.menuOpen) _menuIconController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AppTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuOpen && !oldWidget.menuOpen) {
      _menuIconController.forward();
    } else if (!widget.menuOpen && oldWidget.menuOpen) {
      _menuIconController.reverse();
    }
  }

  @override
  void dispose() {
    _menuIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppBar(
        toolbarHeight: widget.height ?? AppLayout.appBarHeight,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        flexibleSpace: AnimatedContainer(
          duration: AppTheme.mediumAnimation,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.readex(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
            height: 1.2,
          ),
        ),
        leadingWidth: AppTopBar._sideSlotWidth,
        leading: widget.onBackTap != null
            ? Center(
                child: _HeaderIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: widget.onBackTap!,
                ),
              )
            : widget.onMenuTap != null
            ? Center(
                child: _AnimatedMenuCloseButton(
                  animation: _menuIconController,
                  onTap: widget.onMenuTap!,
                ),
              )
            : null,
        actions: [
          if (widget.actions != null && widget.actions!.isNotEmpty)
            ...widget.actions!
          else
            const SizedBox(width: AppTopBar._sideSlotWidth),
        ],
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
    );
  }
}

class _AnimatedMenuCloseButton extends StatelessWidget {
  final AnimationController animation;
  final VoidCallback onTap;

  const _AnimatedMenuCloseButton({
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.92,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final isClose = animation.value > 0.5;
            return AnimatedSwitcher(
              duration: AppMotion.quick,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, transitionAnimation) {
                return ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.7,
                    end: 1.0,
                  ).animate(transitionAnimation),
                  child: FadeTransition(
                    opacity: transitionAnimation,
                    child: child,
                  ),
                );
              },
              child: isClose
                  ? Icon(
                      Icons.close_rounded,
                      key: const ValueKey<bool>(true),
                      color: AppColors.icon(context),
                      size: 22,
                    )
                  : SvgPicture.asset(
                      AppIcons.menu,
                      key: const ValueKey<bool>(false),
                      colorFilter: ColorFilter.mode(
                        AppColors.icon(context),
                        BlendMode.srcIn,
                      ),
                      width: 22,
                      height: 22,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, color: AppColors.icon(context), size: 20),
      ),
    );
  }
}

Future<void> showSubjectTeachersSheet(
  BuildContext context, {
  required String subject,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    sheetAnimationStyle: const AnimationStyle(
      duration: AppMotion.standard,
      reverseDuration: AppMotion.quick,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    ),
    builder: (context) => SubjectTeachersSheet(subject: subject),
  );
}

class SubjectTeachersSheet extends StatelessWidget {
  final String subject;

  const SubjectTeachersSheet({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final teachers = context.select<ApiDataService, List<UserModel>>(
      (data) => data.getTeachersForSubject(subject),
    );
    final colors = AppSubjects.gradientFor(subject);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          boxShadow: AppShadows.raised(Theme.of(context).brightness),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  SubjectIcon(subject: subject, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أساتذة المادة',
                          style: AppFonts.readex(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        Text(
                          subject,
                          style: AppFonts.readex(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PressableScale(
                    pressedScale: 0.9,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.icon(context),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: teachers.isEmpty
                  ? const _EmptyTeachersState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      shrinkWrap: true,
                      itemCount: teachers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return SubjectTeacherListTile(teacher: teachers[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectTeacherListTile extends StatelessWidget {
  final UserModel teacher;

  const SubjectTeacherListTile({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: teacher.name,
            photoPath: teacher.photoPath,
            size: 48,
            showBorder: false,
            showShadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.name,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                if (teacher.email != null && teacher.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    teacher.email!,
                    style: AppFonts.readex(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (teacher.phone != null && teacher.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    teacher.phone!,
                    style: AppFonts.readex(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (teacher.canUploadLectures)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.roleBadgeBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'يرفع',
                style: AppFonts.readex(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.roleBadgeText(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTeachersState extends StatelessWidget {
  const _EmptyTeachersState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.textSecondary(context).withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'لم يُعيَّن أستاذ لهذه المادة بعد',
            textAlign: TextAlign.center,
            style: AppFonts.readex(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ViewTeachersButton extends StatelessWidget {
  final String subject;
  final int teacherCount;
  final bool compact;
  final bool expand;

  const ViewTeachersButton({
    super.key,
    required this.subject,
    required this.teacherCount,
    this.compact = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = compact
        ? 'عرض الأساتذة ($teacherCount)'
        : 'عرض أساتذة المادة';

    return PressableScale(
      pressedScale: 0.97,
      onTap: () => showSubjectTeachersSheet(context, subject: subject),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 8 : 13,
        ),
        decoration: BoxDecoration(
          color: AppColors.roleBadgeBg(context),
          borderRadius: BorderRadius.circular(compact ? 12 : AppRadius.md),
          border: Border.all(color: AppColors.roleBadgeBorder(context)),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: expand
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              Icons.groups_rounded,
              size: compact ? 16 : 20,
              color: AppColors.roleBadgeText(context),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppFonts.readex(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 14,
                  color: AppColors.roleBadgeText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.roleBadgeBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$teacherCount',
                  style: AppFonts.readex(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.roleBadgeText(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SubjectTeacherDisplay extends StatelessWidget {
  final String subject;
  final bool compact;

  const SubjectTeacherDisplay({
    super.key,
    required this.subject,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final teachers = context.select<ApiDataService, List<UserModel>>(
      (data) => data.getTeachersForSubject(subject),
    );

    if (teachers.isEmpty) {
      return Text(
        'لم يُعيَّن بعد',
        style: AppFonts.readex(
          fontSize: compact ? 11 : 12,
          color: AppColors.textSecondary(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (teachers.length == 1) {
      return Row(
        children: [
          Icon(
            Icons.person_rounded,
            size: compact ? 14 : 16,
            color: AppColors.roleBadgeText(context),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              teachers.first.name,
              style: AppFonts.readex(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: AppColors.roleBadgeText(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return ViewTeachersButton(
      subject: subject,
      teacherCount: teachers.length,
      compact: compact,
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final double size;
  final bool showBorder;
  final bool showShadow;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.size = 112,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final isRemote = MediaUrl.isRemote(path);
    final isLocalFile = !isRemote && path != null && File(path).existsSync();
    final borderWidth = (size * 0.035).clamp(2.0, 4.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size * dpr).round().clamp(64, 1080);

    Widget content;
    if (isRemote) {
      content = Image.network(
        MediaUrl.resolve(path!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        cacheWidth: cacheW,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _InitialsAvatar(name: name, size: size);
        },
        errorBuilder: (context, error, stackTrace) =>
            _InitialsAvatar(name: name, size: size),
      );
    } else if (isLocalFile) {
      content = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        cacheWidth: cacheW,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) =>
            _InitialsAvatar(name: name, size: size),
      );
    } else {
      content = _InitialsAvatar(name: name, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: isDark ? AppColors.borderDark : Colors.white,
                width: borderWidth,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.18),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      child: ClipOval(child: content),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialsAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          ProfileRules.initialsFor(name),
          style: AppFonts.readex(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoadingIndicator({super.key, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
}
