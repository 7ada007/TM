import '../../core/core.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';
import '../auth/auth.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

class PremiumGenderSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const PremiumGenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const male = 'ذكر';
  static const female = 'أنثى';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderCard(
            label: male,

            icon: Icons.male_rounded,
            accent: const Color(0xFF0077B6),
            accentDark: const Color(0xFF023E8A),
            isSelected: value == male,
            enabled: enabled,
            onTap: () {
              if (!enabled || value == male) return;
              HapticFeedback.selectionClick();
              onChanged(male);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _GenderCard(
            label: female,
            icon: Icons.female_rounded,
            accent: const Color(0xFF9D4EDD),
            accentDark: const Color(0xFF5A189A),
            isSelected: value == female,
            enabled: enabled,
            onTap: () {
              if (!enabled || value == female) return;
              HapticFeedback.selectionClick();
              onChanged(female);
            },
          ),
        ),
      ],
    );
  }
}

class _GenderCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Color accentDark;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentDark,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_GenderCard> createState() => _GenderCardState();
}

class _GenderCardState extends State<_GenderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 148,
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [widget.accent, widget.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.overlay(0.12)
                          : Colors.white,
                      widget.accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : AppColors.border(context),
              width: widget.isSelected ? 0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? widget.accent.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: widget.isSelected ? 18 : 10,
                offset: Offset(0, widget.isSelected ? 10 : 5),
              ),
              if (widget.isSelected)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 0,
                  offset: const Offset(0, -2),
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18,
                child: _Icon3D(
                  icon: widget.icon,
                  size: 52,
                  color: widget.isSelected ? Colors.white : widget.accent,
                  isSelected: widget.isSelected,
                ),
              ),
              Positioned(
                bottom: 16,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: widget.isSelected
                        ? Colors.white
                        : AppColors.textPrimary(context),
                  ),
                  child: Text(widget.label),
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
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

class _Icon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool isSelected;

  const _Icon3D({
    required this.icon,
    required this.size,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 4),
          child: Icon(
            icon,
            size: size,
            color: (isSelected ? Colors.black : color).withValues(alpha: 0.18),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 2),
          child: Icon(
            icon,
            size: size,
            color: (isSelected ? Colors.white : color).withValues(alpha: 0.45),
          ),
        ),
        Icon(
          icon,
          size: size,
          color: isSelected ? Colors.white : color,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileCommentsActivity extends StatelessWidget {
  final String userId;

  const ProfileCommentsActivity({super.key, required this.userId});

  String _formatDateTime(DateTime dt) {
    return DateFormat('d MMM yyyy • h:mm a', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final comments = data.getCommentsByUser(userId);

    if (comments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'تعليقاتي',
              style: AppFonts.readex(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${comments.length}',
                style: AppFonts.readex(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.itemGap),
        ...comments
            .take(10)
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => _CommentActivityTile(
                comment: entry.value,
                lectureTitle:
                    data.findLectureById(entry.value.lectureId)?.title ??
                    'محاضرة محذوفة',
                animationIndex: entry.key,
                onTap: () {
                  if (data.findLectureById(entry.value.lectureId) != null) {
                    context.push('/lecture/${entry.value.lectureId}');
                  }
                },
                formatDateTime: _formatDateTime,
              ),
            ),
      ],
    );
  }
}

class _CommentActivityTile extends StatelessWidget {
  final CommentModel comment;
  final String lectureTitle;
  final int animationIndex;
  final VoidCallback onTap;
  final String Function(DateTime) formatDateTime;

  const _CommentActivityTile({
    required this.comment,
    required this.lectureTitle,
    required this.animationIndex,
    required this.onTap,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
          pressedScale: 0.98,
          onTap: onTap,
          child: AppCard(
            margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lectureTitle,
                        style: AppFonts.readex(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatDateTime(comment.createdAt),
                      style: AppFonts.readex(
                        fontSize: 10,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: AppFonts.readex(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, delay: (animationIndex * 60).ms)
        .slideY(begin: 0.06, end: 0, duration: 320.ms);
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppTopBar(
          title: 'الملف الشخصي',
          showLogo: false,
          onBackTap: () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: AppLayout.pagePaddingOf(context, bottomExtra: 12),
          child: Column(
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    UserAvatar(
                      name: user?.name ?? '',
                      photoPath: user?.photoPath,
                      size: 112,
                      showShadow: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? '',
                      style: AppFonts.readex(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (user?.username != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${user!.username}',
                        style: AppFonts.readex(
                          fontSize: 14,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                    if (user != null) ...[
                      const SizedBox(height: 14),
                      _RoleBadge(user: user),
                    ],
                    const SizedBox(height: 24),
                    PremiumActionButton(
                      label: 'تعديل الملف الشخصي',
                      onPressed: () => context.push('/edit-profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayout.sectionGap),
              if (user != null) ProfileCommentsActivity(userId: user.id),
              if (user != null) const SizedBox(height: AppLayout.sectionGap),
              if (user != null) ...profileRoleFields(context, user),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> profileRoleFields(BuildContext context, UserModel user) {
  switch (user.role) {
    case UserRole.admin:
      return _adminFields(context, user);
    case UserRole.teacher:
      return _teacherFields(context, user);
    case UserRole.student:
      return _studentFields(context, user);
  }
}

List<Widget> _adminFields(BuildContext context, UserModel user) {
  return [
    _InfoTile(
      icon: Icons.admin_panel_settings_outlined,
      label: 'الدور',
      value: ProfileRules.roleLabel(user.role),
    ),
    if (user.email != null && user.email!.isNotEmpty)
      _InfoTile(
        icon: Icons.email_outlined,
        label: 'البريد الإلكتروني',
        value: user.email!,
      ),
    if (user.phone != null && user.phone!.isNotEmpty)
      _InfoTile(
        icon: Icons.phone_outlined,
        label: 'الهاتف',
        value: user.phone!,
      ),
    _InfoTile(
      icon: Icons.business_rounded,
      label: 'المؤسسة',
      value: 'معهد طريق المجد للتعليم',
    ),
  ];
}

List<Widget> _teacherFields(BuildContext context, UserModel user) {
  return [
    if (user.email != null && user.email!.isNotEmpty)
      _InfoTile(
        icon: Icons.email_outlined,
        label: 'البريد الإلكتروني',
        value: user.email!,
      ),
    if (user.phone != null && user.phone!.isNotEmpty)
      _InfoTile(
        icon: Icons.phone_outlined,
        label: 'الهاتف',
        value: user.phone!,
      ),
    _InfoTile(
      icon: Icons.menu_book_rounded,
      label: 'المواد',
      value: user.subjects.isEmpty
          ? 'لم تُعيَّن بعد'
          : user.subjects.join(' • '),
    ),
    _InfoTile(
      icon: Icons.cloud_upload_outlined,
      label: 'صلاحية رفع المحاضرات',
      value: user.canUploadLectures ? 'مفعّلة' : 'غير مفعّلة',
      valueColor: user.canUploadLectures
          ? AppColors.secondary
          : AppColors.textSecondary(context),
    ),
  ];
}

List<Widget> _studentFields(BuildContext context, UserModel user) {
  return [
    _InfoTile(
      icon: Icons.class_rounded,
      label: 'الشعبة',
      value: user.section ?? '—',
    ),
    _InfoTile(
      icon: Icons.school_outlined,
      label: 'المدرسة',
      value: user.schoolName ?? 'غير محددة',
    ),
    if (user.subjects.isNotEmpty)
      _InfoTile(
        icon: Icons.menu_book_outlined,
        label: 'المواد',
        value: user.subjects.join(' • '),
      ),
  ];
}

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<AuthService>().currentUser;
    final target = context.select<ApiDataService, UserModel?>(
      (data) => data.findUserById(userId),
    );

    final allowed =
        target != null &&
        PermissionUtils.canViewProfileOf(viewer: viewer, target: target);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppTopBar(
        title: 'الملف الشخصي',
        showLogo: false,
        onBackTap: () => context.pop(),
      ),
      body: allowed
          ? _UserProfileBody(
              user: target,
              isSelf: viewer != null && viewer.id == target.id,
            )
          : _ProfileUnavailable(missing: target == null),
    );
  }
}

class _UserProfileBody extends StatelessWidget {
  final UserModel user;
  final bool isSelf;

  const _UserProfileBody({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppLayout.pagePaddingOf(context, bottomExtra: 12),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Column(
              children: [
                UserAvatar(
                  name: user.name,
                  photoPath: user.photoPath,
                  size: 112,
                  showShadow: true,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${user.username}',
                  style: AppFonts.readex(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _RoleBadge(user: user),
                    if (isSelf) const _YouBadge(),
                  ],
                ),
                if (isSelf) ...[
                  const SizedBox(height: 24),
                  PremiumActionButton(
                    label: 'تعديل الملف الشخصي',
                    onPressed: () => context.push('/edit-profile'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          ProfileCommentsActivity(userId: user.id),
          const SizedBox(height: AppLayout.sectionGap),
          ...profileRoleFields(context, user),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms);
  }
}

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'أنت',
        style: AppFonts.readex(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  final bool missing;

  const _ProfileUnavailable({required this.missing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppLayout.pagePaddingOf(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              missing
                  ? Icons.person_search_rounded
                  : Icons.lock_outline_rounded,
              size: 56,
              color: AppColors.textSecondary(context).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              missing ? 'لم يُعثر على هذا الحساب' : 'لا يمكن عرض هذا الملف',
              textAlign: TextAlign.center,
              style: AppFonts.readex(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              missing
                  ? 'قد يكون الحساب حُذف أو لم يعد متاحاً'
                  : 'ليس لديك صلاحية للاطلاع على هذا الملف الشخصي',
              textAlign: TextAlign.center,
              style: AppFonts.readex(
                fontSize: 13,
                height: 1.7,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserModel user;

  const _RoleBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.roleBadgeBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.roleBadgeBorder(context)),
      ),
      child: Text(
        user.localizedRole,
        style: AppFonts.readex(
          color: AppColors.roleBadgeText(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.overlay(0.12)
                  : AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.icon(context), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  value,
                  style: AppFonts.readex(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _picker = ImagePicker();

  String _gender = PremiumGenderSelector.male;
  bool _isSaving = false;
  bool _canChangeName = true;
  String? _nameLockMessage;
  bool _isUploadingPhoto = false;
  double _photoUploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _schoolController.text = user.schoolName ?? '';
    _gender = user.gender;
    _canChangeName = ProfileRules.canChangeName(user);

    if (!_canChangeName) {
      final remaining = ProfileRules.timeUntilNameChange(user);
      if (remaining != null) {
        _nameLockMessage =
            'يمكنك تغيير الاسم بعد ${ProfileRules.formatRemaining(remaining)}';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _showPhotoMenu(bool hasPhoto) {
    if (_isUploadingPhoto) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(sheetContext),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.icon(sheetContext),
              ),
              title: Text(hasPhoto ? 'تغيير الصورة' : 'اختيار صورة'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'إزالة الصورة',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    if (_isUploadingPhoto) return;
    final auth = context.read<AuthService>();
    final data = context.read<ApiDataService>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await data.removeProfilePhoto(user.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!mounted) return;
    auth.refreshCurrentUser();
    setState(() => _isUploadingPhoto = false);
  }

  Future<void> _pickPhoto() async {
    if (_isUploadingPhoto) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 95,
    );
    if (picked == null || !mounted) return;

    final cropped = await cropImageSquare(context, File(picked.path));
    if (cropped == null || !mounted) return;

    final auth = context.read<AuthService>();
    final data = context.read<ApiDataService>();
    final user = auth.currentUser;
    if (user == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isUploadingPhoto = true;
      _photoUploadProgress = 0;
    });
    try {
      await data.saveProfilePhoto(
        cropped,
        user.id,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _photoUploadProgress = p);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!mounted) return;
    auth.refreshCurrentUser();
    setState(() => _isUploadingPhoto = false);
  }

  Future<void> _persistUser(ApiDataService data, UserModel user) async {
    if (user.role == UserRole.student) {
      await data.updateStudent(user);
    } else if (user.role == UserRole.teacher) {
      await data.updateTeacher(user);
    } else {
      await data.updateUser(user);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final data = context.read<ApiDataService>();
    final user = auth.currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final nameChanged = newName != user.name;

    if (nameChanged && !_canChangeName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_nameLockMessage ?? 'لا يمكن تغيير الاسم الآن')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final previousName = user.name;
    final previousNameChangeAt = user.lastNameChangeAt;
    final previousSchool = user.schoolName;
    final previousGender = user.gender;

    if (nameChanged) {
      user.name = newName;
      user.lastNameChangeAt = DateTime.now();
    }

    if (ProfileRules.canEditSchool(user.role)) {
      user.schoolName = _schoolController.text.trim().isEmpty
          ? null
          : _schoolController.text.trim();
    }

    if (ProfileRules.canEditGender(user.role)) {
      user.gender = _gender;
    }

    try {
      await _persistUser(data, user);
    } catch (e) {
      user.name = previousName;
      user.lastNameChangeAt = previousNameChangeAt;
      user.schoolName = previousSchool;
      user.gender = previousGender;
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    auth.refreshCurrentUser();

    if (!mounted) return;
    setState(() => _isSaving = false);

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ الملف الشخصي')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final role = user?.role;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppTopBar(
          title: 'تعديل الملف الشخصي',
          showLogo: false,
          onBackTap: _isSaving ? () {} : () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: AppLayout.pagePaddingOf(context, bottomExtra: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto
                        ? null
                        : () => _showPhotoMenu(
                            (user?.photoPath ?? '').isNotEmpty,
                          ),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: _isUploadingPhoto ? 0.45 : 1,
                          child: UserAvatar(
                            name: user?.name ?? '',
                            photoPath: user?.photoPath,
                            size: 120,
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  value: _photoUploadProgress > 0
                                      ? _photoUploadProgress
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkPrimaryGradient
                                  : AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isUploadingPhoto
                      ? 'جاري رفع الصورة... ${(_photoUploadProgress * 100).toStringAsFixed(0)}%'
                      : 'اضغط لتغيير الصورة',
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 28),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: _canChangeName && !_isSaving,
                        style: AppFonts.readex(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          suffixIcon: !_canChangeName
                              ? Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textSecondary(
                                    context,
                                  ).withValues(alpha: 0.6),
                                )
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'مطلوب';
                          return null;
                        },
                      ),
                      if (_nameLockMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _nameLockMessage!,
                          style: AppFonts.readex(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'يمكن تغيير الاسم مرة كل 3 أيام',
                          style: AppFonts.readex(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                      if (role != null && ProfileRules.canEditSchool(role)) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _schoolController,
                          enabled: !_isSaving,
                          style: AppFonts.readex(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            labelText: 'اسم المدرسة',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                      ],
                      if (role != null && ProfileRules.canEditGender(role)) ...[
                        const SizedBox(height: 24),
                        Text(
                          'الجنس',
                          style: AppFonts.readex(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PremiumGenderSelector(
                          value: _gender,
                          enabled: !_isSaving,
                          onChanged: (g) => setState(() => _gender = g),
                        ),
                      ],
                      if (role == UserRole.admin) ...[
                        const SizedBox(height: 16),
                        Text(
                          'حساب ممثل المعهد — لا يمكن تعديل الشعبة أو المدرسة من هنا.',
                          style: AppFonts.readex(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PremiumActionButton(
                  label: 'حفظ التغييرات',
                  loadingLabel: 'جاري الحفظ...',
                  state: _isSaving
                      ? PremiumButtonState.loading
                      : PremiumButtonState.idle,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();
    final responsive = ResponsiveLayout.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppTopBar(
          title: 'الإعدادات',
          showLogo: false,
          onBackTap: () => context.pop(),
        ),
        body: ListView(
          padding: responsive.pagePadding(bottomExtra: 24),
          children: [
            _SectionHeader(title: 'المظهر'),
            AppCard(
              padding: EdgeInsets.zero,
              child: _SettingTile(
                icon: ThemeModeSelector.iconFor(settings.themeMode),
                title: 'مظهر التطبيق',
                subtitle: ThemeModeSelector.labelFor(settings.themeMode),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textSecondary(context),
                ),
                onTap: () => showThemeModeSheet(context, settings),
              ),
            ),
            SizedBox(height: responsive.spacing(AppLayout.sectionGap)),
            _SectionHeader(title: 'التفضيلات'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'الإشعارات',
                    subtitle: settings.notificationsEnabled
                        ? 'مفعّلة'
                        : 'معطّلة',
                    trailing: Switch.adaptive(
                      value: settings.notificationsEnabled,
                      activeThumbColor: AppColors.secondary,
                      activeTrackColor: AppColors.secondary.withValues(
                        alpha: 0.3,
                      ),
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        settings.toggleNotifications(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppLayout.sectionGap)),
            _SectionHeader(title: 'حول التطبيق'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.info_rounded,
                    title: 'الإصدار',
                    subtitle: AppStrings.version,
                  ),
                  _SettingsDivider(),
                  _SettingTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'سياسة الخصوصية',
                    subtitle: 'تُفتح في المتصفح',
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      textDirection: TextDirection.ltr,
                      color: AppColors.textSecondary(context),
                    ),
                    onTap: () => AppLinks.openUrl(
                      context,
                      AppContactInfo.privacyPolicyUrl,
                      copyLabel: 'رابط سياسة الخصوصية',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  static const _options = [
    (mode: ThemeMode.light, icon: Icons.light_mode_rounded, label: 'فاتح'),
    (
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_rounded,
      label: 'تلقائي',
    ),
    (mode: ThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'داكن'),
  ];

  static IconData iconFor(ThemeMode mode) => _options
      .firstWhere((o) => o.mode == mode, orElse: () => _options[1])
      .icon;

  static String labelFor(ThemeMode mode) => _options
      .firstWhere((o) => o.mode == mode, orElse: () => _options[1])
      .label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _options.indexWhere((o) => o.mode == mode);
    final effectiveIndex = selectedIndex == -1 ? 1 : selectedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPrimaryGradient
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _options[effectiveIndex].icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مظهر التطبيق',
                    style: AppFonts.readex(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _options[effectiveIndex].label,
                      key: ValueKey(effectiveIndex),
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / _options.length;
            return Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.overlay(0.08)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),

              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: segmentWidth * effectiveIndex - 4,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkPrimaryGradient
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark
                                          ? AppColors.accent
                                          : AppColors.primary)
                                      .withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_options.length, (index) {
                        final option = _options[index];
                        final isSelected = index == effectiveIndex;
                        return Expanded(
                          child: _ThemeSegment(
                            icon: option.icon,
                            label: option.label,
                            isSelected: isSelected,
                            onTap: () {
                              if (isSelected) return;
                              HapticFeedback.selectionClick();
                              onChanged(option.mode);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: AppFonts.readex(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showThemeModeSheet(
  BuildContext context,
  AppSettingsService settings,
) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ThemeModeSheet(settings: settings),
  );
}

class _ThemeModeSheet extends StatelessWidget {
  final AppSettingsService settings;

  const _ThemeModeSheet({required this.settings});

  static const _options = [
    (
      mode: ThemeMode.light,
      icon: Icons.light_mode_rounded,
      label: 'فاتح',
      description: 'مظهر فاتح دائماً بغض النظر عن إعدادات الجهاز',
    ),
    (
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_rounded,
      label: 'تلقائي (حسب الجهاز)',
      description: 'يتبع وضع النظام في جهازك تلقائياً',
    ),
    (
      mode: ThemeMode.dark,
      icon: Icons.dark_mode_rounded,
      label: 'داكن',
      description: 'مظهر داكن دائماً بغض النظر عن إعدادات الجهاز',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 18),
            Text(
              'مظهر التطبيق',
              style: AppFonts.readex(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر المظهر الذي يناسبك',
              style: AppFonts.readex(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(_options.length, (index) {
              final option = _options[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _options.length - 1 ? 0 : 10,
                ),
                child:
                    _ThemeOptionCard(
                          icon: option.icon,
                          label: option.label,
                          description: option.description,
                          isSelected: settings.themeMode == option.mode,
                          onTap: () {
                            if (settings.themeMode == option.mode) {
                              Navigator.of(context).pop();
                              return;
                            }
                            HapticFeedback.lightImpact();
                            settings.setThemeMode(option.mode);
                            Future.delayed(
                              const Duration(milliseconds: 180),
                              () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: (60 * index).ms, duration: 260.ms)
                        .slideY(begin: 0.08, end: 0),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? (isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.primaryGradient)
                : null,
            color: isSelected
                ? null
                : (isDark
                      ? AppColors.overlay(0.06)
                      : AppColors.primary.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.border(context),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark
                            ? AppColors.overlay(0.12)
                            : AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppFonts.readex(
                        fontSize: 11.5,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textSecondary(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4),
      child: Text(
        title,
        style: AppFonts.readex(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      color: AppColors.border(context).withValues(alpha: 0.65),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.icon(context), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.readex(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (onTap == null) return content;

    return PressableScale(onTap: onTap, child: content);
  }
}

typedef _HelpFaq = ({IconData icon, String question, String answer});

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey _contactKey = GlobalKey();

  static const List<_HelpFaq> _faqs = [
    (
      icon: Icons.play_circle_outline_rounded,
      question: 'كيف أشاهد المحاضرات؟',
      answer:
          'انتقل إلى تبويب المحاضرات واختر المادة المطلوبة، ثم اضغط على المحاضرة لمشاهدتها بجودة عالية.',
    ),
    (
      icon: Icons.person_add_alt_1_rounded,
      question: 'كيف أحصل على حساب؟',
      answer:
          'تُنشأ الحسابات من قبل إدارة المعهد. يرجى التواصل مع الإدارة لإنشاء حسابك واستلام اسم المستخدم وكلمة المرور.',
    ),
    (
      icon: Icons.lock_reset_rounded,
      question: 'نسيت كلمة المرور، ماذا أفعل؟',
      answer:
          'يرجى التواصل مع إدارة المعهد مباشرة لاستعادة كلمة المرور وتأكيد هويتك.',
    ),
    (
      icon: Icons.badge_outlined,
      question: 'كيف أعدّل بياناتي الشخصية؟',
      answer:
          'افتح القائمة الجانبية ثم "الملف الشخصي"، ومنها اضغط "تعديل الملف الشخصي" لتغيير الاسم أو الصورة أو بقية البيانات.',
    ),
  ];

  Future<void> _scrollToContact() async {
    final target = _contactKey.currentContext;
    if (target == null) return;
    HapticFeedback.selectionClick();
    await Scrollable.ensureVisible(
      target,
      duration: motionDuration(context, AppMotion.emphasized),
      curve: AppMotion.enter,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    Duration motion(Duration value) => motionDuration(context, value);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppTopBar(
        title: 'المساعدة',
        showLogo: false,
        onBackTap: () => context.pop(),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: responsive.pagePadding(bottomExtra: 8),
            children: [
              _HelpHero(onContactTap: _scrollToContact)
                  .animate()
                  .fadeIn(duration: motion(360.ms))
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: motion(360.ms),
                    curve: AppMotion.enter,
                  ),
              SizedBox(height: responsive.spacing(AppLayout.sectionGap)),
              _HelpSectionHeader(
                icon: Icons.quiz_rounded,
                title: 'الأسئلة الشائعة',
                caption: '${_faqs.length} أسئلة',
              ),
              ...List.generate(_faqs.length, (index) {
                final faq = _faqs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
                  child:
                      _HelpFaqCard(
                            icon: faq.icon,
                            question: faq.question,
                            answer: faq.answer,
                          )
                          .animate()
                          .fadeIn(
                            delay: motion((70 + 55 * index).ms),
                            duration: motion(320.ms),
                          )
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: motion(320.ms),
                            curve: AppMotion.enter,
                          ),
                );
              }),
              SizedBox(height: responsive.spacing(AppLayout.blockGap)),
              _HelpSectionHeader(
                key: _contactKey,
                icon: Icons.headset_mic_rounded,
                title: 'تواصل معنا',
                caption: 'الإدارة',
              ),
              const _AdministrationCard()
                  .animate()
                  .fadeIn(delay: motion(240.ms), duration: motion(340.ms))
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: motion(340.ms),
                    curve: AppMotion.enter,
                  ),
              SizedBox(height: responsive.spacing(AppLayout.itemGap)),
              _HelpLinkTile(
                icon: Icons.alternate_email_rounded,
                label: 'البريد الإلكتروني',
                value: AppContactInfo.supportEmail,
                valueDirection: TextDirection.ltr,
                actionIcon: Icons.open_in_new_rounded,
                onTap: () => AppLinks.email(
                  context,
                  AppContactInfo.supportEmail,
                  subject: 'استفسار من تطبيق ${AppStrings.appShortName}',
                ),
                onLongPress: () => AppLinks.copy(
                  context,
                  AppContactInfo.supportEmail,
                  label: 'البريد الإلكتروني',
                ),
              ).animate().fadeIn(
                delay: motion(290.ms),
                duration: motion(340.ms),
              ),
              SizedBox(height: responsive.spacing(AppLayout.itemGap)),
              _HelpLinkTile(
                icon: Icons.privacy_tip_rounded,
                label: 'سياسة الخصوصية',
                value: 'اقرأ السياسة كاملة في المتصفح',
                actionIcon: Icons.open_in_new_rounded,
                onTap: () => AppLinks.openUrl(
                  context,
                  AppContactInfo.privacyPolicyUrl,
                  copyLabel: 'رابط سياسة الخصوصية',
                ),
              ).animate().fadeIn(
                delay: motion(330.ms),
                duration: motion(340.ms),
              ),
              SizedBox(height: responsive.spacing(34)),
              const _HelpCredits().animate().fadeIn(
                delay: motion(380.ms),
                duration: motion(420.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  final VoidCallback onContactTap;

  const _HelpHero({required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(
              alpha: isDark ? 0.42 : 0.28,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -30,
            top: -42,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          PositionedDirectional(
            end: 44,
            bottom: -54,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كيف يمكننا مساعدتك؟',
                          style: AppFonts.readex(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'إجابات سريعة لأكثر الأسئلة شيوعاً، وتواصل مباشر مع إدارة المعهد',
                          style: AppFonts.readex(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _HeroActionButton(
                icon: Icons.phone_in_talk_rounded,
                label: 'التواصل مع الإدارة',
                onTap: onContactTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: Colors.white.withValues(alpha: 0.16),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: Colors.white),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.readex(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _HelpSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? caption;

  const _HelpSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.itemGap, right: 2),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.roleBadgeBg(context),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 17,
                color: AppColors.roleBadgeText(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppFonts.readex(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: AppFonts.readex(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpFaqCard extends StatefulWidget {
  final IconData icon;
  final String question;
  final String answer;

  const _HelpFaqCard({
    required this.icon,
    required this.question,
    required this.answer,
  });

  @override
  State<_HelpFaqCard> createState() => _HelpFaqCardState();
}

class _HelpFaqCardState extends State<_HelpFaqCard> {
  bool _expanded = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.roleBadgeText(context);

    return MergeSemantics(
      child: Semantics(
        expanded: _expanded,
        child: AnimatedContainer(
          duration: motionDuration(context, AppMotion.quick),
          curve: AppMotion.standardCurve,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _expanded
                  ? AppColors.roleBadgeBorder(context)
                  : AppColors.border(context),
            ),
            boxShadow: AppShadows.of(Theme.of(context).brightness),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: motionDuration(context, AppMotion.quick),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _expanded
                                ? accent.withValues(alpha: 0.18)
                                : AppColors.roleBadgeBg(context),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(widget.icon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.question,
                            style: AppFonts.readex(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              height: 1.5,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: motionDuration(context, AppMotion.standard),
                          curve: AppMotion.enter,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceAlt(context),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 19,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    MotionSize(
                      child: _expanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 1,
                                    color: AppColors.border(context),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.answer,
                                    style: AppFonts.readex(
                                      fontSize: 13,
                                      height: 1.8,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdministrationCard extends StatelessWidget {
  const _AdministrationCard();

  @override
  Widget build(BuildContext context) {
    const contacts = AppContactInfo.administration;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < contacts.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 4,
                endIndent: 4,
                color: AppColors.border(context).withValues(alpha: 0.7),
              ),
            _AdminContactRow(contact: contacts[i]),
          ],
        ],
      ),
    );
  }
}

class _AdminContactRow extends StatelessWidget {
  final AdminContact contact;

  const _AdminContactRow({required this.contact});

  void _call(BuildContext context) {
    AppLinks.dial(
      context,
      contact.dialPhone,
      displayPhone: contact.displayPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MergeSemantics(
      child: Semantics(
        button: true,
        hint: 'اتصال',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _call(context),
            onLongPress: () => AppLinks.copy(
              context,
              contact.displayPhone,
              label: 'رقم ${contact.name}',
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDark
                          ? AppColors.darkPrimaryGradient
                          : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      contact.initial,
                      style: AppFonts.readex(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: AppFonts.readex(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          contact.displayPhone,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: AppFonts.readex(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: AppColors.textSecondary(context),
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ExcludeSemantics(
                    child: _CallButton(onTap: () => _call(context)),
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

class _CallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.roleBadgeBg(context),
      shape: CircleBorder(
        side: BorderSide(color: AppColors.roleBadgeBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.call_rounded,
            size: 20,
            color: AppColors.roleBadgeText(context),
          ),
        ),
      ),
    );
  }
}

class _HelpLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final TextDirection? valueDirection;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _HelpLinkTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.onTap,
    this.valueDirection,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: AppCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.roleBadgeBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: AppColors.roleBadgeText(context),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppFonts.readex(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(context),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                value,
                                textDirection: valueDirection,
                                style: AppFonts.readex(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                  height: 1.4,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      actionIcon,
                      size: 18,
                      textDirection: TextDirection.ltr,
                      color: AppColors.textSecondary(
                        context,
                      ).withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCredits extends StatelessWidget {
  const _HelpCredits();

  static const _entries = [
    (icon: Icons.bolt_rounded, label: 'POWERED BY', value: 'Hayder'),
    (icon: Icons.code_rounded, label: 'DEVELOPED BY', value: 'M.H – A.T'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: _CreditsRule(fadeFromStart: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface(context),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: AppShadows.of(Theme.of(context).brightness),
                ),
                child: Image.asset(
                  AppIcons.logoMark,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.school_rounded,
                    size: 18,
                    color: AppColors.roleBadgeText(context),
                  ),
                ),
              ),
            ),
            const Expanded(child: _CreditsRule()),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.5)
                : AppColors.surfaceAltLight.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.border(context).withValues(alpha: 0.8),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  children: [
                    for (var i = 0; i < _entries.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            height: 1,
                            color: AppColors.border(context),
                          ),
                        ),
                      _CreditEntry(
                        icon: _entries[i].icon,
                        label: _entries[i].label,
                        value: _entries[i].value,
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _CreditEntry(
                      icon: _entries[0].icon,
                      label: _entries[0].label,
                      value: _entries[0].value,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: AppColors.border(context),
                  ),
                  Expanded(
                    child: _CreditEntry(
                      icon: _entries[1].icon,
                      label: _entries[1].label,
                      value: _entries[1].value,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${AppStrings.appName} · الإصدار ${AppStrings.version}',
          textAlign: TextAlign.center,
          style: AppFonts.readex(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context).withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _CreditsRule extends StatelessWidget {
  final bool fadeFromStart;

  const _CreditsRule({this.fadeFromStart = false});

  @override
  Widget build(BuildContext context) {
    final line = AppColors.border(context);
    final colors = fadeFromStart
        ? [line.withValues(alpha: 0), line]
        : [line, line.withValues(alpha: 0)];

    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: colors,
        ),
      ),
    );
  }
}

class _CreditEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CreditEntry({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.textSecondary(context).withValues(alpha: 0.75);

    return MergeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: muted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.readex(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      height: 1.3,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  (isDark
                          ? AppColors.darkPrimaryGradient
                          : AppColors.primaryGradient)
                      .createShader(bounds),
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<File?> cropImageSquare(BuildContext context, File file) {
  return Navigator.of(context).push<File>(
    MaterialPageRoute<File>(
      fullscreenDialog: true,
      builder: (_) => _ImageCropScreen(file: file),
    ),
  );
}

class _ImageCropScreen extends StatefulWidget {
  final File file;

  const _ImageCropScreen({required this.file});

  @override
  State<_ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<_ImageCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final logical = boundary.size.shortestSide;
      const target = 1024.0;
      final ratio = (target / logical).clamp(1.0, 6.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) {
        throw Exception('تعذّر معالجة الصورة');
      }
      final out = File(
        '${Directory.systemTemp.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070C),
        foregroundColor: Colors.white,
        title: Text(
          'قص الصورة',
          style: AppFonts.readex(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'إلغاء',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          _busy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _confirm,
                  child: Text(
                    'تم',
                    style: AppFonts.readex(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.accent,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ColoredBox(
                    color: const Color(0xFF05070C),
                    child: InteractiveViewer(
                      transformationController: _controller,
                      minScale: 1,
                      maxScale: 6,
                      clipBehavior: Clip.hardEdge,
                      child: Image.file(
                        widget.file,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'حرّك الصورة وكبّرها لضبط الإطار',
            style: AppFonts.readex(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
