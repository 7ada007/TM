import 'dart:math' as math;

export 'constants.dart';
export 'models.dart';
export 'services.dart';
export 'shared_widgets.dart';
export 'permission_utils.dart';
export 'api_client.dart';
export 'api_data_service.dart';
export 'api_data_service_ext.dart';

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
        commentSelfDeleteWindow -
        DateTime.now().difference(comment.createdAt);
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

  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
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

class ResponsiveLayout {
  ResponsiveLayout._(this._context);

  final BuildContext _context;

  static ResponsiveLayout of(BuildContext context) =>
      ResponsiveLayout._(context);

  MediaQueryData get _mq => MediaQuery.of(_context);
  Size get size => _mq.size;
  EdgeInsets get padding => _mq.padding;
  EdgeInsets get viewPadding => _mq.viewPadding;
  double get devicePixelRatio => _mq.devicePixelRatio;
  double get textScale => _mq.textScaler.scale(1).clamp(0.85, 1.15);

  double get scaleFactor {
    final width = size.width;
    if (width >= 430) return 1.1;
    if (width >= 390) return 1.04;
    if (width >= 360) return 1.0;
    return 0.94;
  }

  bool get isCompact => size.width < 360;
  bool get isLargePhone => size.width >= 400;
  bool get hasBottomInset => padding.bottom > 0;
  bool get hasTopInset => padding.top > 0;

  double spacing(double base) => base * scaleFactor;

  double get horizontalPadding {
    final inset = math.max(padding.left, padding.right);
    return (size.width * 0.048 + inset * 0.15).clamp(16.0, 28.0);
  }

  double get bottomNavOuterPadding =>
      spacing(6) + math.max(padding.bottom, viewPadding.bottom);

  double get bottomNavHeight => spacing(58).clamp(54.0, 64.0);

  double get appBarHeight => spacing(50).clamp(48.0, 56.0);

  double get navIconSize => spacing(26).clamp(24.0, 30.0);

  double get drawerMenuIconSize => spacing(26).clamp(24.0, 30.0);

  double get statIconSize => spacing(22).clamp(20.0, 26.0);

  double get drawerWidth =>
      (size.width * (isLargePhone ? 0.62 : 0.68)).clamp(248.0, 300.0);

  EdgeInsets pagePadding({double bottomExtra = 0, bool includeTop = false}) {
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      includeTop ? spacing(14) + padding.top : spacing(14),
      horizontalPadding,
      spacing(24) + bottomExtra,
    );
  }

  EdgeInsets listPadding({bool hasFab = false}) {
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      0,
      horizontalPadding,
      spacing(24) + (hasFab ? spacing(84) : 0),
    );
  }

  EdgeInsets get shellHorizontalSafe => EdgeInsets.symmetric(
    horizontal: math.max(padding.left, padding.right) * 0.35,
  );

  EdgeInsetsDirectional get scrollRowPadding {
    final h = horizontalPadding;
    return EdgeInsetsDirectional.only(
      start: h + padding.left,
      end: h + padding.right,
    );
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
