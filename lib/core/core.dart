import 'dart:math' as math;

export 'app_links.dart';
export 'monitoring_models.dart';
export 'notification_service.dart';
export 'realtime_service.dart';
export 'watch_tracker.dart';
export 'constants.dart';
export 'models.dart';
export 'services.dart';
export 'shared_widgets.dart';
export 'permission_utils.dart';
export 'api_client.dart';
export 'api_data_service.dart';
export 'api_data_service_ext.dart';
export 'screen_guard.dart';

import 'models.dart';
import 'package:flutter/material.dart';

abstract final class PermissionUtils {
  static bool isAdmin(UserModel? user) => user?.role == UserRole.admin;

  static bool isTeacher(UserModel? user) => user?.role == UserRole.teacher;

  static bool isStudent(UserModel? user) => user?.role == UserRole.student;

  static bool canAccessControlPanel(UserModel? user) => isAdmin(user);

  static bool canAccessAttendance(UserModel? user) =>
      isAdmin(user) || isTeacher(user);

  static bool canManageAccounts(UserModel? user) => isAdmin(user);

  static bool canManageRoles(UserModel? user) => isAdmin(user);

  static bool canAddStudent(UserModel? user) => isAdmin(user);

  static bool canUploadLectures(UserModel? user) =>
      isAdmin(user) || (isTeacher(user) && (user?.canUploadLectures ?? false));

  static bool canManageOwnLectures(UserModel? user) =>
      isAdmin(user) || isTeacher(user);

  static bool canViewAssignedSubjects(UserModel? user) =>
      isAdmin(user) || isTeacher(user);

  static bool seesAllGenders(UserModel? user) =>
      isAdmin(user) || isTeacher(user);

  static List<UserModel> visibleStudentsFor(
    UserModel? viewer,
    List<UserModel> students,
  ) {
    if (viewer == null) return const [];
    if (seesAllGenders(viewer)) return students;
    return students.where((s) => s.gender == viewer.gender).toList();
  }

  static bool canViewProfileOf({
    required UserModel? viewer,
    required UserModel target,
  }) {
    if (viewer == null) return false;
    if (viewer.id == target.id) return true;
    if (seesAllGenders(viewer)) return true;
    if (target.role != UserRole.student) return true;
    return target.gender == viewer.gender;
  }

  static bool canPromoteToAdmin(UserModel? actor) => isAdmin(actor);

  static bool canAssignTeacherRole(UserModel? actor) => isAdmin(actor);

  static bool canDeleteUser({
    required UserModel? actor,
    required UserModel target,
  }) {
    if (!isAdmin(actor)) return false;

    if (actor!.isSuperAdmin) {
      return actor.id != target.id;
    }

    if (target.isSuperAdmin) return false;

    if (target.role == UserRole.admin) return false;

    return true;
  }

  static bool canChangeRole({
    required UserModel? actor,
    required UserModel target,
    required UserRole newRole,
  }) {
    if (!isAdmin(actor)) return false;
    if (target.role == UserRole.admin && target.id != actor!.id) {
      return false;
    }
    if (newRole == UserRole.admin && target.role != UserRole.admin) {
      return true;
    }
    if (target.role == UserRole.admin) {
      return false;
    }
    return true;
  }

  static String roleLabel(UserRole role) => switch (role) {
    UserRole.admin => 'مشرف',
    UserRole.teacher => 'أستاذ',
    UserRole.student => 'طالب',
  };

  static const commentSelfDeleteWindow = Duration(minutes: 14);

  static bool canRateLecture(UserModel? user) => user != null;

  static bool canDeleteComment({
    required UserModel? user,
    required CommentModel comment,
  }) {
    if (user == null) return false;
    if (isAdmin(user)) return true;
    if (user.id != comment.userId) return false;
    return DateTime.now().difference(comment.createdAt) <
        commentSelfDeleteWindow;
  }

  static Duration? commentDeletableFor({
    required UserModel? user,
    required CommentModel comment,
  }) {
    if (user == null || user.id != comment.userId) return null;
    final remaining =
        commentSelfDeleteWindow - DateTime.now().difference(comment.createdAt);
    return remaining.isNegative ? null : remaining;
  }
}

abstract final class ProfileRules {
  static const nameChangeCooldown = Duration(days: 3);

  static bool canChangeName(UserModel user) {
    final lastChange = user.lastNameChangeAt;
    if (lastChange == null) return true;
    return DateTime.now().difference(lastChange) >= nameChangeCooldown;
  }

  static Duration? timeUntilNameChange(UserModel user) {
    final lastChange = user.lastNameChangeAt;
    if (lastChange == null) return null;
    final remaining =
        nameChangeCooldown - DateTime.now().difference(lastChange);
    return remaining.isNegative ? null : remaining;
  }

  static String formatRemaining(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    if (days > 0) return '$days يوم${hours > 0 ? ' و $hours ساعة' : ''}';
    if (hours > 0) return '$hours ساعة';
    final minutes = duration.inMinutes % 60;
    return '$minutes دقيقة';
  }

  static final RegExp _arabicLetter = RegExp(r'[؀-ۿ]');

  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first;
    if (_arabicLetter.hasMatch(first.substring(0, 1))) {
      return first.substring(0, 1);
    }
    if (parts.length == 1) return first.substring(0, 1).toUpperCase();
    return '${first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static String roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ممثل المعهد';
      case UserRole.teacher:
        return 'أستاذ';
      case UserRole.student:
        return 'طالب';
    }
  }

  static bool showsAcademicFields(UserRole role) => role == UserRole.student;

  static bool showsTeacherFields(UserRole role) => role == UserRole.teacher;

  static bool showsAdminFields(UserRole role) => role == UserRole.admin;

  static bool canEditSchool(UserRole role) => role == UserRole.student;

  static bool canEditGender(UserRole role) => role == UserRole.teacher;

  static bool showsGender(UserRole role) => role != UserRole.student;
}

/// Physical form factor the UI is being laid out for.
///
/// Derived from the shortest side so a device does not change class when it is
/// rotated — an iPhone in landscape is still a phone, an iPad in portrait is
/// still a tablet. Split-view sizing is handled separately, via [paneWidth].
enum DeviceClass {
  /// iPhone SE (1st gen) and other 320pt-wide screens.
  compactPhone,

  /// iPhone 8 / SE2 / 13 mini class, 360–389pt.
  phone,

  /// iPhone 14–17 and Pro Max class, 390pt and up.
  largePhone,

  /// iPad mini / 11" class, 600–833pt shortest side.
  tablet,

  /// iPad Pro 12.9" class, 834pt and up.
  largeTablet,
}

/// Single source of truth for every size, gutter and inset in the app.
///
/// Everything is derived from the live [MediaQueryData] rather than from
/// hardcoded device checks, so the same code covers iPhone 8 through iPhone 17
/// Pro Max, Android 9 through 15, and the full iPad range including Split View
/// and Slide Over, where the app's window is much narrower than the screen.
class ResponsiveLayout {
  ResponsiveLayout._(this._mq);

  final MediaQueryData _mq;

  static ResponsiveLayout of(BuildContext context) =>
      ResponsiveLayout._(MediaQuery.of(context));

  Size get size => _mq.size;
  EdgeInsets get padding => _mq.padding;
  EdgeInsets get viewPadding => _mq.viewPadding;
  EdgeInsets get viewInsets => _mq.viewInsets;
  double get devicePixelRatio => _mq.devicePixelRatio;

  /// Effective text scale, clamped to the same range `main.dart` enforces on
  /// the MediaQuery so size calculations agree with what is actually painted.
  double get textScale => _mq.textScaler.scale(1).clamp(0.9, 1.15);

  /// Width of the window the app actually owns. On iPad this is the Split View
  /// pane, not the display, so a 1/3-width pane lays out with phone rules.
  double get paneWidth => size.width;

  double get shortestSide => size.shortestSide;

  bool get isLandscape => size.width > size.height;

  DeviceClass get deviceClass {
    final s = shortestSide;
    if (s >= 834) return DeviceClass.largeTablet;
    if (s >= 600) return DeviceClass.tablet;
    if (s >= 390) return DeviceClass.largePhone;
    if (s >= 360) return DeviceClass.phone;
    return DeviceClass.compactPhone;
  }

  /// True for physical tablets. Note this stays true in Split View — use
  /// [isWideCanvas] when the decision depends on available width instead.
  bool get isTablet =>
      deviceClass == DeviceClass.tablet ||
      deviceClass == DeviceClass.largeTablet;

  /// True when there is genuinely enough width for tablet-grade layout:
  /// side-by-side panes, wider gutters, multi-column forms.
  bool get isWideCanvas => paneWidth >= 700;

  /// True when the window is wide enough for two comfortable content columns.
  bool get isExpandedCanvas => paneWidth >= 1000;

  /// Multiplier applied to every nominal spacing value.
  double get scaleFactor => switch (deviceClass) {
    DeviceClass.compactPhone => 0.94,
    DeviceClass.phone => 1.0,
    DeviceClass.largePhone => paneWidth >= 430 ? 1.1 : 1.04,
    DeviceClass.tablet => 1.18,
    DeviceClass.largeTablet => 1.26,
  };

  bool get isCompact => deviceClass == DeviceClass.compactPhone;
  bool get isLargePhone => shortestSide >= 400;
  bool get hasBottomInset => padding.bottom > 0;
  bool get hasTopInset => padding.top > 0;

  /// True on hardware with a home indicator / gesture bar rather than a
  /// physical home button, which needs extra bottom clearance.
  bool get hasGestureBar => viewPadding.bottom >= 20;

  double spacing(double base) => base * scaleFactor;

  /// Font size helper: text scales less aggressively than layout, so a tablet
  /// gets more content rather than merely bigger content.
  double fontSize(double base) =>
      base * (1 + (scaleFactor - 1) * 0.45).clamp(0.94, 1.14);

  /// Side gutter measured from the window edge, before safe-area insets.
  double get horizontalPadding => switch (deviceClass) {
    DeviceClass.compactPhone => 16.0,
    DeviceClass.phone => 18.0,
    DeviceClass.largePhone => 20.0,
    DeviceClass.tablet => isLandscape ? 40.0 : 32.0,
    DeviceClass.largeTablet => isLandscape ? 56.0 : 44.0,
  };

  /// Widest a single reading column is ever allowed to get. Beyond this, extra
  /// width becomes margin instead of longer lines — the difference between a
  /// layout designed for iPad and a phone layout stretched across one.
  double get maxContentWidth => switch (deviceClass) {
    DeviceClass.tablet => 720.0,
    DeviceClass.largeTablet => 820.0,
    _ => double.infinity,
  };

  /// Cap for full-bleed surfaces (grids, dashboards) that can use more width
  /// than a reading column but still should not span a 12.9" display edge to
  /// edge.
  double get maxWideContentWidth => switch (deviceClass) {
    DeviceClass.tablet => 980.0,
    DeviceClass.largeTablet => 1180.0,
    _ => double.infinity,
  };

  /// Extra symmetric inset that centres content inside [maxContentWidth].
  double centeringInset({double? maxWidth}) {
    final cap = maxWidth ?? maxContentWidth;
    if (!cap.isFinite) return 0;
    final available = paneWidth - horizontalPadding * 2;
    if (available <= cap) return 0;
    return (available - cap) / 2;
  }

  /// Number of grid columns that fit while keeping each item at least
  /// [minItemWidth] wide.
  int gridColumns({
    required double minItemWidth,
    int min = 1,
    int max = 6,
    double? availableWidth,
    double spacing = 12,
  }) {
    final width = (availableWidth ?? (paneWidth - horizontalPadding * 2)).clamp(
      1.0,
      double.infinity,
    );
    final fit = ((width + spacing) / (minItemWidth + spacing)).floor();
    return fit.clamp(min, max);
  }

  double get bottomNavOuterPadding =>
      spacing(6) + math.max(padding.bottom, viewPadding.bottom);

  double get bottomNavHeight => switch (deviceClass) {
    DeviceClass.tablet => 68.0,
    DeviceClass.largeTablet => 72.0,
    _ => spacing(58).clamp(54.0, 64.0),
  };

  /// The bottom navigation bar is a floating pill; on a wide canvas it is
  /// centred at a comfortable width instead of spanning the whole display.
  double get bottomNavMaxWidth => switch (deviceClass) {
    DeviceClass.tablet => 620.0,
    DeviceClass.largeTablet => 680.0,
    _ => double.infinity,
  };

  double get appBarHeight => switch (deviceClass) {
    DeviceClass.tablet => 58.0,
    DeviceClass.largeTablet => 62.0,
    _ => spacing(50).clamp(48.0, 56.0),
  };

  double get navIconSize => switch (deviceClass) {
    DeviceClass.tablet => 28.0,
    DeviceClass.largeTablet => 30.0,
    _ => spacing(26).clamp(24.0, 30.0),
  };

  double get drawerMenuIconSize => switch (deviceClass) {
    DeviceClass.tablet => 28.0,
    DeviceClass.largeTablet => 30.0,
    _ => spacing(26).clamp(24.0, 30.0),
  };

  double get statIconSize => spacing(22).clamp(20.0, 28.0);

  double get drawerWidth {
    if (isTablet) {
      return (paneWidth * 0.42).clamp(320.0, 400.0);
    }
    return (paneWidth * (isLargePhone ? 0.62 : 0.68)).clamp(248.0, 320.0);
  }

  /// Minimum tappable edge length. 44pt is Apple's HIG floor and also clears
  /// Material's 48dp guidance once the surrounding padding is counted.
  static const double minTapTarget = 44;

  /// Bottom inset a scrollable needs so its last row clears the home
  /// indicator / gesture bar.
  ///
  /// Reads zero when something upstream has already consumed it — a `SafeArea`
  /// or a `Scaffold` with a bottom navigation bar both strip the inset from the
  /// MediaQuery they hand down — so adding this is never double counting.
  double get safeBottom => padding.bottom;

  EdgeInsets pagePadding({double bottomExtra = 0, bool includeTop = false}) {
    final inset = centeringInset();
    return EdgeInsets.fromLTRB(
      horizontalPadding + inset,
      includeTop ? spacing(14) + padding.top : spacing(14),
      horizontalPadding + inset,
      spacing(24) + bottomExtra + safeBottom,
    );
  }

  EdgeInsets listPadding({bool hasFab = false, bool wide = false}) {
    final inset = centeringInset(
      maxWidth: wide ? maxWideContentWidth : maxContentWidth,
    );
    return EdgeInsets.fromLTRB(
      horizontalPadding + inset,
      0,
      horizontalPadding + inset,
      spacing(24) + (hasFab ? spacing(84) : 0) + safeBottom,
    );
  }

  /// Horizontal safe inset for the app shell. Uses the full notch/curvature
  /// inset so nothing is clipped by a rounded corner or a landscape notch.
  EdgeInsets get shellHorizontalSafe =>
      EdgeInsets.only(left: padding.left, right: padding.right);

  EdgeInsetsDirectional get scrollRowPadding {
    final h = horizontalPadding + centeringInset(maxWidth: maxWideContentWidth);
    return EdgeInsetsDirectional.only(start: h, end: h);
  }
}

abstract final class VideoFormatUtils {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
