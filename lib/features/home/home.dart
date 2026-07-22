import '../../core/core.dart';
import '../../theme/theme.dart';
import '../../theme/motion.dart';
import '../classmates/classmates.dart';
import '../community/community.dart';
import '../lectures/lectures.dart';
import '../assistant/assistant_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ShellTabs extends InheritedWidget {
  final ValueChanged<int> select;

  const ShellTabs({super.key, required this.select, required super.child});

  static ShellTabs? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellTabs>();

  @override
  bool updateShouldNotify(ShellTabs oldWidget) => false;
}

class AppShellScaffold extends StatefulWidget {
  final List<Widget> pages;
  final List<String> tabTitles;
  final List<PremiumNavItem> navItems;
  final bool showAdminMenuItem;

  const AppShellScaffold({
    super.key,
    required this.pages,
    required this.tabTitles,
    required this.navItems,
    this.showAdminMenuItem = false,
  });

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  int _currentIndex = 0;
  bool _menuOpen = false;

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  void _closeMenu() {
    if (_menuOpen) setState(() => _menuOpen = false);
  }

  void _handleNavigate(String route) => context.push(route);

  void _onTabTap(int index) {
    if (index != _currentIndex && index < widget.pages.length) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ApiDataService>();
    final user = context.watch<AuthService>().currentUser;
    final responsive = ResponsiveLayout.of(context);

    assert(
      widget.pages.length == widget.navItems.length &&
          widget.pages.length == widget.tabTitles.length,
      'pages, navItems, and tabTitles must have the same length',
    );

    return ShellTabs(
      select: _onTabTap,
      child: AssistantDraggableFab(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: AppTopBar(
            onMenuTap: _toggleMenu,
            title: widget.tabTitles[_currentIndex],
            height: responsive.appBarHeight,
            menuOpen: _menuOpen,
          ),
          body: Padding(
            padding: responsive.shellHorizontalSafe,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IndexedStack(index: _currentIndex, children: widget.pages),
                PremiumNavigationMenu(
                  isOpen: _menuOpen,
                  onClose: _closeMenu,
                  onNavigate: _handleNavigate,
                  userName: user?.name ?? '',
                  userPhotoPath: user?.photoPath,
                  userRoleLabel: user == null
                      ? ''
                      : PermissionUtils.roleLabel(user.role),
                  showAdminPanel: widget.showAdminMenuItem,
                ),
              ],
            ),
          ),
          bottomNavigationBar: PremiumBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabTap,
            items: widget.navItems,
          ),
        ),
      ),
    );
  }
}

class ShellTabBody extends StatelessWidget {
  final Widget child;
  final bool hasFab;

  const ShellTabBody({super.key, required this.child, this.hasFab = false});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: hasFab ? responsive.spacing(AppLayout.fabClearance * 0.35) : 0,
      ),
      child: child,
    );
  }
}

class ShellTabScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const ShellTabScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ShellTabBody(hasFab: floatingActionButton != null, child: body),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavItem> items;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    final navHeight = responsive.bottomNavHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          responsive.spacing(4),
          responsive.horizontalPadding,
          responsive.bottomNavOuterPadding,
        ),
        child: Container(
          height: navHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: AppShadows.raised(Theme.of(context).brightness),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Row(
              children: List.generate(items.length, (index) {
                return Expanded(
                  child: RepaintBoundary(
                    child: _NavTab(
                      item: items[index],
                      isSelected: currentIndex == index,
                      iconSize: responsive.navIconSize,
                      onTap: () => onTap(index),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final PremiumNavItem item;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.secondary.withValues(alpha: 0.10),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppNavIcon(
              kind: item.iconKind,
              selected: isSelected,
              size: iconSize,
            ),
            SizedBox(height: iconSize * 0.12),
            AnimatedDefaultTextStyle(
              duration: AppMotion.quick,
              curve: Curves.easeOutCubic,
              style: AppFonts.readex(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : AppColors.textSecondary(context),
                height: 1.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumNavItem {
  final AppIconKind iconKind;
  final String label;

  const PremiumNavItem({required this.iconKind, required this.label});
}

void showPremiumLogoutDialog(BuildContext context, AuthService auth) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: AppFonts.readex(
            fontWeight: FontWeight.bold,
            color: AppColors.error_(context),
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: AppFonts.readex(color: AppColors.textPrimary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'إلغاء',
              style: AppFonts.readex(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withValues(alpha: 0.5),
                builder: (_) => const Center(child: AppLoadingIndicator()),
              );

              await Future.delayed(AppMotion.deliberate);

              if (context.mounted) {
                Navigator.pop(context);
                auth.logout();
                context.go('/login');
              }
            },
            child: Text(
              'خروج',
              style: AppFonts.readex(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class PremiumNavigationMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;
  final String userName;
  final String? userPhotoPath;
  final String userRoleLabel;
  final bool showAdminPanel;

  const PremiumNavigationMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onNavigate,
    required this.userName,
    this.userPhotoPath,
    this.userRoleLabel = '',
    this.showAdminPanel = false,
  });

  @override
  State<PremiumNavigationMenu> createState() => _PremiumNavigationMenuState();
}

class _PremiumNavigationMenuState extends State<PremiumNavigationMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backdrop;
  late final Animation<Offset> _panelSlide;
  late final Animation<double> _panelFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.emphasized,
      reverseDuration: AppMotion.standard,
    );
    final openCurve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    _backdrop = openCurve;
    _panelSlide = Tween<Offset>(
      begin: const Offset(1.05, 0),
      end: Offset.zero,
    ).animate(openCurve);
    _panelFade = Tween<double>(begin: 0, end: 1).animate(openCurve);

    if (widget.isOpen) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant PremiumNavigationMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNavigate(String route) {
    HapticFeedback.lightImpact();
    widget.onClose();
    Future.delayed(AppMotion.quick, () {
      widget.onNavigate(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isOpen && _controller.isDismissed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              if (_backdrop.value > 0)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.4 * _backdrop.value,
                    ),
                  ),
                ),
              SlideTransition(
                position: _panelSlide,
                child: FadeTransition(
                  opacity: _panelFade,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _MenuPanel(
                      animation: _controller,
                      userName: widget.userName,
                      userPhotoPath: widget.userPhotoPath,
                      userRoleLabel: widget.userRoleLabel,
                      showAdminPanel: widget.showAdminPanel,
                      onClose: widget.onClose,
                      onNavigate: _handleNavigate,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final Animation<double> animation;
  final String userName;
  final String? userPhotoPath;
  final String userRoleLabel;
  final bool showAdminPanel;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  const _MenuPanel({
    required this.animation,
    required this.userName,
    this.userPhotoPath,
    this.userRoleLabel = '',
    this.showAdminPanel = false,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    final height = MediaQuery.sizeOf(context).height;
    final width = responsive.drawerWidth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = responsive.spacing(20);
    final avatarSize = responsive.spacing(76).clamp(68.0, 84.0);
    final menuIconSize = responsive.spacing(26).clamp(24.0, 30.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(
          right: responsive.spacing(8),
          bottom: responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(AppRadius.lg),
          ),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppShadows.raised(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad * 0.4, 4, hPad * 0.4, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 24),
                    color: AppColors.textSecondary(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  children: [
                    UserAvatar(
                      name: userName,
                      photoPath: userPhotoPath,
                      size: avatarSize,
                      showShadow: true,
                    ),
                    SizedBox(height: responsive.spacing(14)),
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        fontSize: responsive.spacing(17).clamp(16.0, 18.0),
                        color: AppColors.textPrimary(context),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userRoleLabel.isNotEmpty) ...[
                      SizedBox(height: responsive.spacing(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(14),
                          vertical: responsive.spacing(5),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.roleBadgeBg(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.roleBadgeBorder(context),
                          ),
                        ),
                        child: Text(
                          userRoleLabel,
                          style: AppFonts.readex(
                            color: AppColors.roleBadgeText(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(22)),
              Divider(
                height: 1,
                indent: hPad,
                endIndent: hPad,
                color: AppColors.border(context),
              ),
              SizedBox(height: responsive.spacing(12)),
              _MenuItem(
                animation: animation,
                index: 0,
                iconKind: AppIconKind.profile,
                iconSize: menuIconSize,
                label: 'الملف الشخصي',
                horizontalPadding: hPad,
                onTap: () => onNavigate('/profile'),
              ),
              _MenuItem(
                animation: animation,
                index: 1,
                iconKind: AppIconKind.settings,
                iconSize: menuIconSize,
                label: 'الإعدادات',
                horizontalPadding: hPad,
                onTap: () => onNavigate('/settings'),
              ),
              _MenuItem(
                animation: animation,
                index: 2,
                iconKind: AppIconKind.help,
                iconSize: menuIconSize,
                label: 'المساعدة',
                horizontalPadding: hPad,
                onTap: () => onNavigate('/help'),
              ),
              if (showAdminPanel)
                _MenuItem(
                  animation: animation,
                  index: 3,
                  iconKind: AppIconKind.controlPanel,
                  iconSize: menuIconSize,
                  label: 'لوحة التحكم',
                  horizontalPadding: hPad,
                  onTap: () => onNavigate('/admin/control-panel'),
                ),
              const Spacer(),
              Divider(
                height: 1,
                indent: hPad,
                endIndent: hPad,
                color: AppColors.border(context),
              ),
              SizedBox(height: responsive.spacing(12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final auth = context.read<AuthService>();
                      showPremiumLogoutDialog(context, auth);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.error_(context),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'تسجيل الخروج',
                            style: AppFonts.readex(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error_(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  0,
                  hPad,
                  responsive.spacing(20),
                ),
                child: Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
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

class _MenuItem extends StatefulWidget {
  final Animation<double> animation;
  final int index;
  final AppIconKind iconKind;
  final double iconSize;
  final String label;
  final double horizontalPadding;
  final VoidCallback onTap;

  const _MenuItem({
    required this.animation,
    required this.index,
    required this.iconKind,
    required this.iconSize,
    required this.label,
    required this.horizontalPadding,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final delay = 0.06 + widget.index * 0.055;
    final itemHPad = widget.horizontalPadding * 0.55;
    final responsive = ResponsiveLayout.of(context);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          ((widget.animation.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(16 * (1 - progress), 0),
          child: Opacity(opacity: progress, child: child),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: itemHPad,
          vertical: responsive.spacing(3),
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: AppMotion.instant,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(14),
                vertical: responsive.spacing(13),
              ),
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.roleBadgeBg(context)
                    : AppColors.surfaceAlt(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: _pressed
                      ? AppColors.roleBadgeBorder(context)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: widget.iconSize + 12,
                    child: AppAssetIcon.kind(
                      kind: widget.iconKind,
                      size: widget.iconSize,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: AppColors.textSecondary(
                      context,
                    ).withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeGreetingHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget? badge;
  final Widget? trailing;

  const HomeGreetingHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.badge,
    this.trailing,
  });

  static String greetingNow() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'صباح الخير';
    if (hour >= 12 && hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingNow(),
                  style: AppFonts.readex(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppFonts.readex(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppFonts.readex(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null) ...[const SizedBox(height: 10), badge!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class HomeHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const HomeHeaderBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.readex(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.readex(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            PressableScale(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: AppFonts.readex(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roleBadgeText(context),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: AppColors.roleBadgeText(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HomeStatTile extends StatelessWidget {
  final AppIconKind? iconKind;
  final IconData? icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const HomeStatTile({
    super.key,
    this.iconKind,
    this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: iconKind != null
                ? AppAssetIcon.kind(kind: iconKind!, size: 22, tintColor: color)
                : Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppFonts.readex(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.readex(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class HomeLectureTile extends StatelessWidget {
  final LectureModel lecture;

  const HomeLectureTile({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/lecture/${lecture.id}'),
      child: Row(
        children: [
          SubjectIcon(subject: lecture.subject, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.title,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  lecture.subject +
                      (lecture.teacherName.isNotEmpty
                          ? ' • ${lecture.teacherName}'
                          : ''),
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.roleBadgeBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.roleBadgeText(context),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final data = context.watch<ApiDataService>();
    if (user == null) return const SizedBox.shrink();

    final subjects = user.subjects;
    final lectures =
        data.getLecturesForStudent(
          subjects: subjects,
          section: user.section ?? '',
        )..sort(
          (a, b) =>
              (b.publishedAt ?? b.date).compareTo(a.publishedAt ?? a.date),
        );
    final recent = lectures.take(3).toList();
    final classmatesCount = data.students
        .where((s) => s.gender == user.gender && s.id != user.id)
        .length;
    final posts = data.communityPosts;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              HomeGreetingHeader(
                name: user.name,
                subtitle: 'واصل رحلتك نحو التفوق، كل محاضرة خطوة نحو المجد',
                badge: user.section != null
                    ? HomeHeaderBadge(
                        icon: Icons.class_rounded,
                        label: user.section!,
                      )
                    : null,
                trailing: UserAvatar(
                  name: user.name,
                  photoPath: user.photoPath,
                  size: 58,
                  showShadow: false,
                ),
              ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.04, end: 0),
              const SizedBox(height: AppLayout.blockGap),
              Row(
                children: [
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.lectures,
                      label: 'محاضرة متاحة',
                      value: '${lectures.length}',
                      color: AppColors.primary,
                      onTap: () => ShellTabs.of(context)?.select(1),
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: HomeStatTile(
                      icon: Icons.menu_book_rounded,
                      label: 'مادة دراسية',
                      value: '${subjects.length}',
                      color: AppColors.secondary,
                      onTap: () => ShellTabs.of(context)?.select(1),
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.classmates,
                      label: 'زميل',
                      value: '$classmatesCount',
                      color: AppColors.info_(context),
                      onTap: () => ShellTabs.of(context)?.select(2),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 60.ms, duration: 340.ms),
              const SizedBox(height: AppLayout.sectionGap),
              if (recent.isNotEmpty) ...[
                HomeSectionTitle(
                  title: 'أحدث المحاضرات',
                  actionLabel: 'عرض الكل',
                  onAction: () => ShellTabs.of(context)?.select(1),
                ),
                ...recent.asMap().entries.map(
                  (e) => HomeLectureTile(lecture: e.value)
                      .animate()
                      .fadeIn(delay: (100 + 60 * e.key).ms, duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                ),
                const SizedBox(height: AppLayout.blockGap),
              ],
              if (subjects.isNotEmpty) ...[
                const HomeSectionTitle(title: 'موادي الدراسية'),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppLayout.itemGap),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return PressableScale(
                        onTap: () =>
                            showSubjectTeachersSheet(context, subject: subject),
                        child: Container(
                          width: 96,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SubjectIcon(
                                subject: subject,
                                size: 44,
                                showShadow: false,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subject,
                                style: AppFonts.readex(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(
                        delay: (140 + 40 * index).ms,
                        duration: 280.ms,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppLayout.sectionGap),
              ],
              if (posts.isNotEmpty) ...[
                HomeSectionTitle(
                  title: 'من المجتمع',
                  actionLabel: 'فتح المجتمع',
                  onAction: () => ShellTabs.of(context)?.select(3),
                ),
                AppCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  onTap: () => ShellTabs.of(context)?.select(3),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: posts.first.userName,
                        photoPath: posts.first.userPhotoPath,
                        size: 42,
                        showShadow: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (posts.first.isPinned) ...[
                                  Icon(
                                    Icons.push_pin_rounded,
                                    size: 13,
                                    color: AppColors.roleBadgeText(context),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    posts.first.userName,
                                    style: AppFonts.readex(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              posts.first.title?.trim().isNotEmpty == true
                                  ? posts.first.title!
                                  : posts.first.content,
                              style: AppFonts.readex(
                                fontSize: 12.5,
                                color: AppColors.textSecondary(context),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 320.ms),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      tabTitles: const ['الرئيسية', 'المحاضرات', 'الزملاء', 'المجتمع'],
      pages: const [
        StudentHomeTab(),
        LecturesScreen(showAppBar: false),
        ClassmatesScreen(showAppBar: false),
        CommunityScreen(showAppBar: false),
      ],
      navItems: const [
        PremiumNavItem(iconKind: AppIconKind.home, label: 'الرئيسية'),
        PremiumNavItem(iconKind: AppIconKind.lectures, label: 'المحاضرات'),
        PremiumNavItem(iconKind: AppIconKind.classmates, label: 'الزملاء'),
        PremiumNavItem(iconKind: AppIconKind.community, label: 'المجتمع'),
      ],
    );
  }
}
