import '../../core/core.dart';
import '../../theme/theme.dart';
import '../auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum ControlPanelSection {
  overview,
  accounts,
  roles,
  attendance,
  subjects,
  addStudent,
  addTeacher,
}

extension ControlPanelSectionX on ControlPanelSection {
  String get label => switch (this) {
    ControlPanelSection.overview => 'نظرة عامة',
    ControlPanelSection.accounts => 'الحسابات',
    ControlPanelSection.roles => 'الصلاحيات',
    ControlPanelSection.attendance => 'الحضور',
    ControlPanelSection.subjects => 'المواد',
    ControlPanelSection.addStudent => 'إضافة طالب',
    ControlPanelSection.addTeacher => 'إضافة أستاذ',
  };

  IconData get icon => switch (this) {
    ControlPanelSection.overview => Icons.dashboard_rounded,
    ControlPanelSection.accounts => Icons.people_alt_rounded,
    ControlPanelSection.roles => Icons.admin_panel_settings_rounded,
    ControlPanelSection.attendance => Icons.fact_check_rounded,
    ControlPanelSection.subjects => Icons.menu_book_rounded,
    ControlPanelSection.addStudent => Icons.person_add_alt_1_rounded,
    ControlPanelSection.addTeacher => Icons.school_rounded,
  };
}

class ControlPanelStatCard extends StatelessWidget {
  final AppIconKind? iconKind;
  final IconData? icon;
  final String label;
  final String value;
  final Color color;

  const ControlPanelStatCard({
    super.key,
    this.iconKind,
    this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: iconKind != null
                ? AppAssetIcon.kind(kind: iconKind!, size: 26)
                : Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppFonts.readex(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppFonts.readex(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlPanelNavBar extends StatefulWidget {
  final ControlPanelSection selected;
  final ValueChanged<ControlPanelSection> onSelected;

  const ControlPanelNavBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<ControlPanelNavBar> createState() => _ControlPanelNavBarState();
}

class _ControlPanelNavBarState extends State<ControlPanelNavBar> {
  final ScrollController _scrollController = ScrollController();
  late final Map<ControlPanelSection, GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = {
      for (final section in ControlPanelSection.values) section: GlobalKey(),
    };
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollSelectedIntoView(),
    );
  }

  @override
  void didUpdateWidget(ControlPanelNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollSelectedIntoView(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollSelectedIntoView() {
    if (!mounted) return;
    final context = _itemKeys[widget.selected]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    final navHeight = responsive.spacing(46).clamp(44.0, 52.0);
    final isCompact = responsive.isCompact;
    final pillHPad = isCompact ? 10.0 : 14.0;
    final labelSize = (isCompact ? 11.0 : 12.0) * responsive.textScale;

    return SizedBox(
      height: navHeight,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: responsive.scrollRowPadding,
        itemCount: ControlPanelSection.values.length,
        separatorBuilder: (_, _) => SizedBox(width: responsive.spacing(8)),
        itemBuilder: (context, index) {
          final section = ControlPanelSection.values[index];
          final isSelected = section == widget.selected;

          return KeyedSubtree(
            key: _itemKeys[section],
            child: PressableScale(
              onTap: () => widget.onSelected(section),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: pillHPad,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.overlay(0.12)
                            : AppColors.primary.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.border(context).withValues(alpha: 0.8),
                  ),
                  boxShadow: isSelected ? AppShadows.soft(blur: 10) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      section.icon,
                      size: isCompact ? 15 : 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.icon(context),
                    ),
                    SizedBox(width: responsive.spacing(6)),
                    Text(
                      section.label,
                      style: AppFonts.readex(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 30).ms, duration: 280.ms),
          );
        },
      ),
    );
  }
}

class ControlPanelHubCard extends StatelessWidget {
  final ControlPanelSection section;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  const ControlPanelHubCard({
    super.key,
    required this.section,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(section.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badge',
                      style: AppFonts.readex(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              section.label,
              style: AppFonts.readex(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppFonts.readex(
                fontSize: 12,
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showUserEditDialog(BuildContext context, UserModel user) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _UserEditDialog(user: user),
  );
}

class _UserEditDialog extends StatefulWidget {
  final UserModel user;

  const _UserEditDialog({required this.user});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _schoolController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;
  late final TextEditingController _notesController;

  late String _section;
  late String _gender;
  late UserRole _role;
  late bool _canUpload;
  late Map<String, bool> _subjects;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u.name);
    _usernameController = TextEditingController(text: u.username);

    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: u.phone ?? '');
    _emailController = TextEditingController(text: u.email ?? '');
    _schoolController = TextEditingController(text: u.schoolName ?? '');
    _guardianNameController = TextEditingController(text: u.guardianName ?? '');
    _guardianPhoneController = TextEditingController(
      text: u.guardianPhone ?? '',
    );
    _notesController = TextEditingController(text: u.notes ?? '');
    _section = u.section ?? AppSections.all.first;
    _gender = u.gender;
    _role = u.role;
    _canUpload = u.canUploadLectures;
    _subjects = {for (final s in AppSubjects.all) s: u.subjects.contains(s)};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      setState(() => _error = 'الاسم واسم المستخدم مطلوبان');
      return;
    }

    final auth = context.read<AuthService>();
    final data = context.read<ApiDataService>();
    final updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),

      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      schoolName: _schoolController.text.trim().isEmpty
          ? null
          : _schoolController.text.trim(),
      guardianName: _guardianNameController.text.trim().isEmpty
          ? null
          : _guardianNameController.text.trim(),
      guardianPhone: _guardianPhoneController.text.trim().isEmpty
          ? null
          : _guardianPhoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      section: _section,
      gender: _gender,
      role: _role,
      canUploadLectures: _canUpload,
      subjects: _subjects.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
    );

    final error = await data.updateUserSafely(
      updated: updated,
      actor: auth.currentUser,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    auth.refreshCurrentUser();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isAdminTarget = widget.user.role == UserRole.admin;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: AppCard(
        padding: const EdgeInsets.all(20),
        borderRadius: AppRadius.lg,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تعديل الحساب',
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: AppFonts.readex(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(_nameController, 'الاسم *', Icons.person_outline),
                      _field(
                        _usernameController,
                        'اسم المستخدم *',
                        Icons.alternate_email,
                      ),
                      PasswordTextField(
                        controller: _passwordController,
                        labelText:
                            'كلمة المرور الجديدة (اتركها فارغة لعدم التغيير)',
                      ),
                      const SizedBox(height: 12),
                      _field(_phoneController, 'الهاتف', Icons.phone_outlined),
                      _field(_emailController, 'البريد', Icons.email_outlined),
                      _field(
                        _schoolController,
                        'المدرسة',
                        Icons.school_outlined,
                      ),
                      const SizedBox(height: 8),
                      PremiumSectionSelector(
                        value: _section,
                        onChanged: (v) => setState(() => _section = v),
                      ),
                      const SizedBox(height: 12),
                      _PremiumDropdownField<UserRole>(
                        label: 'الدور',
                        value: _role,
                        items: UserRole.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(PermissionUtils.roleLabel(r)),
                              ),
                            )
                            .toList(),
                        onChanged:
                            isAdminTarget &&
                                widget.user.id !=
                                    context.read<AuthService>().currentUser?.id
                            ? null
                            : (v) => setState(() => _role = v!),
                      ),
                      if (_role == UserRole.teacher) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'صلاحية رفع المحاضرات',
                            style: AppFonts.readex(fontSize: 14),
                          ),
                          value: _canUpload,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _canUpload = v),
                        ),
                      ],
                      const SizedBox(height: 12),
                      PremiumSubjectSelector(
                        selected: _subjects,
                        onToggle: (s) => setState(
                          () => _subjects[s] = !(_subjects[s] ?? false),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _guardianNameController,
                        'اسم ولي الأمر',
                        Icons.family_restroom_outlined,
                      ),
                      _field(
                        _guardianPhoneController,
                        'هاتف ولي الأمر',
                        Icons.phone_android_outlined,
                      ),
                      _field(_notesController, 'ملاحظات', Icons.notes_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: AppFonts.readex(fontWeight: FontWeight.w500),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class ControlPanelOverviewTab extends StatelessWidget {
  final ValueChanged<ControlPanelSection>? onNavigate;

  const ControlPanelOverviewTab({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'نظرة عامة',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.textPrimary(context),
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                'ملخص شامل للمنصة',
                style: AppFonts.readex(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppLayout.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: ControlPanelStatCard(
                      icon: Icons.people_alt_rounded,
                      label: 'إجمالي الحسابات',
                      value: '${data.getAllUsers().length}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: ControlPanelStatCard(
                      iconKind: AppIconKind.students,
                      label: 'الطلاب',
                      value: '${data.students.length}',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 60.ms),
              const SizedBox(height: AppLayout.itemGap),
              Row(
                children: [
                  Expanded(
                    child: ControlPanelStatCard(
                      iconKind: AppIconKind.teachers,
                      label: 'الأساتذة',
                      value: '${data.teachers.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: ControlPanelStatCard(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'المشرفون',
                      value: '${data.admins.length}',
                      color: const Color(0xFF5C4AE4),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: AppLayout.itemGap),
              Row(
                children: [
                  Expanded(
                    child: ControlPanelStatCard(
                      iconKind: AppIconKind.lectures,
                      label: 'المحاضرات',
                      value: '${data.lectures.length}',
                      color: const Color(0xFF2D6A4F),
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: ControlPanelStatCard(
                      icon: Icons.fact_check_rounded,
                      label: 'سجلات الحضور',
                      value: '${data.attendanceRecords.length}',
                      color: const Color(0xFF0077B6),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 140.ms),
              if (onNavigate != null) ...[
                const SizedBox(height: AppLayout.sectionGap),
                Text(
                  'الأقسام',
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppLayout.itemGap,
                  crossAxisSpacing: AppLayout.itemGap,
                  childAspectRatio: 1.15,
                  children: [
                    ControlPanelHubCard(
                      section: ControlPanelSection.accounts,
                      subtitle: 'إدارة جميع الحسابات',
                      badge: data.getAllUsers().length,
                      onTap: () => onNavigate!(ControlPanelSection.accounts),
                    ),
                    ControlPanelHubCard(
                      section: ControlPanelSection.roles,
                      subtitle: 'إدارة الأدوار والصلاحيات',
                      onTap: () => onNavigate!(ControlPanelSection.roles),
                    ),
                    ControlPanelHubCard(
                      section: ControlPanelSection.attendance,
                      subtitle: 'تسجيل ومتابعة الحضور',
                      onTap: () => onNavigate!(ControlPanelSection.attendance),
                    ),
                    ControlPanelHubCard(
                      section: ControlPanelSection.addStudent,
                      subtitle: 'إنشاء حساب طالب جديد',
                      onTap: () => onNavigate!(ControlPanelSection.addStudent),
                    ),
                    ControlPanelHubCard(
                      section: ControlPanelSection.addTeacher,
                      subtitle: 'إنشاء حساب أستاذ جديد',
                      onTap: () => onNavigate!(ControlPanelSection.addTeacher),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppLayout.sectionGap),
              Text(
                'المواد الدراسية',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppLayout.itemGap,
                  crossAxisSpacing: AppLayout.itemGap,
                  childAspectRatio: 1.35,
                ),
                itemCount: AppSubjects.all.length,
                itemBuilder: (context, index) {
                  final subject = AppSubjects.all[index];
                  return AppCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SubjectIcon(subject: subject, size: 40),
                        const Spacer(),
                        Text(
                          subject,
                          style: AppFonts.readex(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        SubjectTeacherDisplay(subject: subject, compact: true),
                      ],
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class ControlPanelAccountsTab extends StatefulWidget {
  const ControlPanelAccountsTab({super.key});

  @override
  State<ControlPanelAccountsTab> createState() =>
      _ControlPanelAccountsTabState();
}

class _ControlPanelAccountsTabState extends State<ControlPanelAccountsTab> {
  final _searchController = TextEditingController();
  UserRole? _roleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filteredUsers(ApiDataService data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.getAllUsers().where((u) {
      if (_roleFilter != null && u.role != _roleFilter) return false;
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query) ||
          (u.section?.toLowerCase().contains(query) ?? false) ||
          (u.schoolName?.toLowerCase().contains(query) ?? false);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final auth = context.watch<AuthService>();
    final users = _filteredUsers(data);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'إدارة الحسابات',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${data.getAllUsers().length} حساب مسجل',
                style: AppFonts.readex(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو اسم المستخدم...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _roleFilter == null,
                      onTap: () => setState(() {
                        _roleFilter = null;
                      }),
                    ),
                    ...UserRole.values.map(
                      (r) => _FilterChip(
                        label: PermissionUtils.roleLabel(r),
                        selected: _roleFilter == r,
                        onTap: () => setState(
                          () => _roleFilter = _roleFilter == r ? null : r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        if (users.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'لا توجد حسابات مطابقة',
                style: AppFonts.readex(color: AppColors.textSecondary(context)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: AppLayout.listPaddingOf(context),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = users[index];

                final canReset =
                    PermissionUtils.isAdmin(auth.currentUser) &&
                    (!user.isSuperAdmin || auth.currentUser?.id == user.id);

                return _AccountCard(
                      user: user,
                      onEdit: () async {
                        final saved = await showUserEditDialog(context, user);
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث الحساب')),
                          );
                        }
                      },
                      onResetPassword: canReset
                          ? () => showResetPasswordDialog(context, user)
                          : null,
                      onDelete:
                          PermissionUtils.canDeleteUser(
                            actor: auth.currentUser,
                            target: user,
                          )
                          ? () => _confirmDelete(context, user)
                          : null,
                    )
                    .animate()
                    .fadeIn(delay: (index * 40).ms, duration: 320.ms)
                    .slideY(begin: 0.04, end: 0);
              }, childCount: users.length),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text('هل تريد حذف حساب "${user.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await context.read<ApiDataService>().deleteUserData(
      userId: user.id,
      actor: context.read<AuthService>().currentUser,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حذف الحساب'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected
                ? null
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.overlay(0.06)
                      : AppColors.primary.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: AppFonts.readex(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onResetPassword;

  const _AccountCard({
    required this.user,
    required this.onEdit,
    this.onDelete,
    this.onResetPassword,
  });

  Color _roleColor(UserRole role) => switch (role) {
    UserRole.admin => const Color(0xFF5C4AE4),
    UserRole.teacher => AppColors.primary,
    UserRole.student => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: user.name,
                photoPath: user.photoPath,
                size: 44,
                showShadow: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppFonts.readex(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '@${user.username}',
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(label: user.localizedRole, color: _roleColor(user.role)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(Icons.school_outlined, user.section ?? '—'),
              _InfoChip(Icons.apartment_outlined, user.schoolName ?? '—'),
              _InfoChip(
                Icons.calendar_today_outlined,
                user.registrationDateLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                ),
              ),
              if (onResetPassword != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onResetPassword,
                  tooltip: 'إعادة تعيين كلمة المرور',
                  icon: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'حذف',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppFonts.readex(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppFonts.readex(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlPanelAttendanceTab extends StatefulWidget {
  const ControlPanelAttendanceTab({super.key});

  @override
  State<ControlPanelAttendanceTab> createState() =>
      _ControlPanelAttendanceTabState();
}

class _ControlPanelAttendanceTabState extends State<ControlPanelAttendanceTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _section = AppSections.all.first;
  String? _subject;
  final _searchController = TextEditingController();
  final _recordSearchController = TextEditingController();
  final Map<String, AttendanceStatus> _draft = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _studentsForSection(ApiDataService data) {
    final query = _recordSearchController.text.trim().toLowerCase();
    return data.students
        .where(
          (s) =>
              s.section == _section &&
              (query.isEmpty || s.name.toLowerCase().contains(query)),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<String> _availableSubjects(AuthService auth, ApiDataService data) {
    if (auth.isAdmin) return AppSubjects.all;
    final user = auth.currentUser;
    if (user == null) return [];
    return data.getSubjectsForTeacher(user.id);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _draft.clear();
      });
    }
  }

  void _setStatus(String studentId, AttendanceStatus status) {
    setState(() => _draft[studentId] = status);
  }

  Future<void> _saveAll(BuildContext context) async {
    final auth = context.read<AuthService>();
    final data = context.read<ApiDataService>();
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.currentUser;
    if (user == null) return;

    final entries = _draft.entries.toList();
    var successCount = 0;
    var failureCount = 0;
    for (final entry in entries) {
      try {
        await data.recordAttendance(
          studentId: entry.key,
          section: _section,
          subject: _subject ?? '',
          date: _selectedDate,
          status: entry.value,
          recordedBy: user.id,
          recordedByName: user.name,
        );
        successCount++;
        _draft.remove(entry.key);
      } catch (_) {
        failureCount++;
      }
    }

    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failureCount == 0
              ? 'تم حفظ $successCount سجل حضور'
              : 'تم حفظ $successCount سجل، وتعذّر حفظ $failureCount سجل. حاول مرة أخرى',
        ),
        backgroundColor: failureCount == 0 ? null : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<ApiDataService>();
    final subjects = _availableSubjects(auth, data);

    return Column(
      children: [
        Padding(
          padding: AppLayout.pagePaddingOf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الحضور والغياب',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary(context),
                indicatorColor: AppColors.secondary,
                tabs: const [
                  Tab(text: 'تسجيل'),
                  Tab(text: 'السجل'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RecordTab(
                selectedDate: _selectedDate,
                section: _section,
                subject: _subject ?? '',
                subjects: subjects,
                draft: _draft,
                students: _studentsForSection(data),
                searchController: _recordSearchController,
                onSearchChanged: () => setState(() {}),
                onPickDate: _pickDate,
                onSectionChanged: (v) => setState(() {
                  _section = v;
                  _draft.clear();
                }),
                onSubjectChanged: (v) => setState(() => _subject = v),
                onStatusChanged: _setStatus,
                onSave: () => _saveAll(context),
              ),
              _HistoryTab(
                searchController: _searchController,
                section: _section,
                onSectionChanged: (v) => setState(() => _section = v),
                onSearchChanged: () => setState(() {}),
                recordedBy: auth.isTeacher ? auth.currentUser?.id : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;

  final ValueChanged<T?>? onChanged;

  const _PremiumDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.icon(context),
      ),
      dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      style: AppFonts.readex(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? AppColors.overlay(0.08)
            : AppColors.primary.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.6),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _RecordTab extends StatelessWidget {
  final DateTime selectedDate;
  final String section;
  final String? subject;
  final List<String> subjects;
  final Map<String, AttendanceStatus> draft;
  final List<UserModel> students;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final VoidCallback onPickDate;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String?> onSubjectChanged;
  final void Function(String, AttendanceStatus) onStatusChanged;
  final VoidCallback onSave;

  const _RecordTab({
    required this.selectedDate,
    required this.section,
    required this.subject,
    required this.subjects,
    required this.draft,
    required this.students,
    required this.searchController,
    required this.onSearchChanged,
    required this.onPickDate,
    required this.onSectionChanged,
    required this.onSubjectChanged,
    required this.onStatusChanged,
    required this.onSave,
  });

  String get _dateLabel =>
      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.horizontalOf(context),
            0,
            AppLayout.horizontalOf(context),
            12,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: onPickDate,
                      child: AppCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _dateLabel,
                              style: AppFonts.readex(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'بحث عن طالب',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => onSearchChanged(),
              ),
              const SizedBox(height: 10),
              _PremiumDropdownField<String>(
                label: 'الشعبة',
                value: AppSections.all.contains(section)
                    ? section
                    : AppSections.all.first,
                items: AppSections.all
                    .toSet()
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => onSectionChanged(v!),
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PremiumDropdownField<String?>(
                  label: 'المادة (اختياري)',
                  value: (subjects.contains(subject) ? subject : null),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-')),
                    ...subjects.toSet().map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: onSubjectChanged,
                ),
              ],
              if (draft.isNotEmpty) ...[
                const SizedBox(height: 10),
                PressableScale(
                  onTap: onSave,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'حفظ ${draft.length} سجل',
                      textAlign: TextAlign.center,
                      style: AppFonts.readex(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? Center(
                  child: Text(
                    'لا يوجد طلاب في هذه الشعبة',
                    style: AppFonts.readex(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: AppLayout.listPaddingOf(context),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final status = draft[student.id];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: AppFonts.readex(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _StatusButton(
                                label: 'حضور',
                                selected: status == AttendanceStatus.present,
                                color: AppColors.success,
                                onTap: () => onStatusChanged(
                                  student.id,
                                  AttendanceStatus.present,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusButton(
                                label: 'لم يحضر',
                                selected: status == AttendanceStatus.absent,
                                color: AppColors.error,
                                onTap: () => onStatusChanged(
                                  student.id,
                                  AttendanceStatus.absent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusButton(
                                label: 'مجاز',
                                selected: status == AttendanceStatus.excused,
                                color: AppColors.warning,
                                onTap: () => onStatusChanged(
                                  student.id,
                                  AttendanceStatus.excused,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 30).ms);
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.readex(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final TextEditingController searchController;
  final String section;
  final ValueChanged<String> onSectionChanged;
  final VoidCallback onSearchChanged;
  final String? recordedBy;

  const _HistoryTab({
    required this.searchController,
    required this.section,
    required this.onSectionChanged,
    required this.onSearchChanged,
    this.recordedBy,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final records = data.getAttendanceRecords(
      section: section == 'الكل' ? null : section,
      query: searchController.text,
      recordedBy: recordedBy,
    );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.horizontalOf(context),
            0,
            AppLayout.horizontalOf(context),
            12,
          ),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الشعبة...',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              _PremiumDropdownField<String>(
                label: 'تصفية الشعبة',
                value: (section == 'الكل' || AppSections.all.contains(section))
                    ? section
                    : 'الكل',
                items: [
                  const DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                  ...AppSections.all.toSet().map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (v) => onSectionChanged(v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد سجلات',
                    style: AppFonts.readex(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: AppLayout.listPaddingOf(context),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _HistoryCard(
                      record: record,
                    ).animate().fadeIn(delay: (index * 30).ms);
                  },
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AttendanceRecordModel record;

  const _HistoryCard({required this.record});

  Color _statusColor(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => AppColors.success,
    AttendanceStatus.absent => AppColors.error,
    AttendanceStatus.excused => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(record.status),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: AppFonts.readex(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${record.section} • ${record.dateKey}'
                  '${record.subject != null ? ' • ${record.subject}' : ''}',
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  'بواسطة ${record.recordedByName}',
                  style: AppFonts.readex(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(record.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.statusLabel,
              style: AppFonts.readex(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusColor(record.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlPanelSubjectsTab extends StatelessWidget {
  const ControlPanelSubjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'المواد الدراسية',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'عرض الأساتذة المعينين لكل مادة',
                style: AppFonts.readex(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/admin/add-teacher'),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('إضافة أستاذ'),
                ),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: AppLayout.listPaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final subject = AppSubjects.all[index];
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectIcon(subject: subject, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            subject,
                            style: AppFonts.readex(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SubjectTeacherDisplay(subject: subject),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 35).ms);
            }, childCount: AppSubjects.all.length),
          ),
        ),
      ],
    );
  }
}

class ControlPanelRolesTab extends StatelessWidget {
  const ControlPanelRolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final users = List<UserModel>.from(data.getAllUsers())
      ..sort((a, b) {
        if (a.isSuperAdmin && !b.isSuperAdmin) return -1;
        if (!a.isSuperAdmin && b.isSuperAdmin) return 1;

        final roleOrder = {
          UserRole.admin: 0,
          UserRole.teacher: 1,
          UserRole.student: 2,
        };
        return (roleOrder[a.role] ?? 3).compareTo(roleOrder[b.role] ?? 3);
      });

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'الأدوار والصلاحيات',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'تعيين الأدوار دون استبدال المشرفين الحاليين',
                style: AppFonts.readex(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              AppCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'عند تعيين مشرف جديد، يُضاف دور المشرف لحسابه الخاص '
                        'دون استبدال أو حذف أي مشرف موجود.',
                        style: AppFonts.readex(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _PermissionMatrix(),
            ]),
          ),
        ),
        SliverPadding(
          padding: AppLayout.listPaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final user = users[index];
              return _RoleUserCard(
                user: user,
              ).animate().fadeIn(delay: (index * 40).ms, duration: 320.ms);
            }, childCount: users.length),
          ),
        ),
      ],
    );
  }
}

class _PermissionMatrix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مصفوفة الصلاحيات',
            style: AppFonts.readex(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _matrixRow('إدارة الحسابات', admin: true, teacher: false),
          _matrixRow('تعيين الأدوار', admin: true, teacher: false),
          _matrixRow('رفع المحاضرات', admin: true, teacher: true),
          _matrixRow('إدارة محاضراتي', admin: true, teacher: true),
          _matrixRow('عرض المواد المعينة', admin: true, teacher: true),
          _matrixRow('قسم الحضور', admin: true, teacher: true),
        ],
      ),
    );
  }

  Widget _matrixRow(
    String label, {
    required bool admin,
    required bool teacher,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: AppFonts.readex(fontSize: 13)),
          ),
          _check(admin),
          const SizedBox(width: 16),
          _check(teacher),
        ],
      ),
    );
  }

  Widget _check(bool allowed) {
    return Icon(
      allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
      size: 18,
      color: allowed
          ? AppColors.success
          : AppColors.error.withValues(alpha: 0.5),
    );
  }
}

class _RoleUserCard extends StatelessWidget {
  final UserModel user;

  const _RoleUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isSelf = auth.currentUser?.id == user.id;
    final isOtherAdmin = user.role == UserRole.admin && !isSelf;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppFonts.readex(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '@${user.username}',
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: user.role == UserRole.admin
                      ? AppColors.primaryGradient
                      : null,
                  color: user.role != UserRole.admin
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  user.localizedRole,
                  style: AppFonts.readex(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.role == UserRole.admin
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (isOtherAdmin) ...[
            const SizedBox(height: 10),
            Text(
              'حساب مشرف محمي — لا يمكن تعديل دوره',
              style: AppFonts.readex(fontSize: 12, color: AppColors.warning),
            ),
          ] else if (user.role != UserRole.admin) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.role != UserRole.admin)
                  _ActionChip(
                    label: 'تعيين مشرف',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => _promoteAdmin(context),
                  ),
                if (user.role != UserRole.teacher)
                  _ActionChip(
                    label: 'تعيين أستاذ',
                    icon: Icons.school_outlined,
                    onTap: () => _assignTeacher(context),
                  ),
                if (user.role != UserRole.student)
                  _ActionChip(
                    label: 'تعيين طالب',
                    icon: Icons.person_outline,
                    onTap: () => _assignStudent(context),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _promoteAdmin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعيين مشرف'),
        content: Text(
          'سيتم إضافة دور المشرف لحساب "${user.name}" '
          'دون التأثير على المشرفين الحاليين. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    String? error;
    try {
      error = await context.read<ApiDataService>().promoteToAdmin(user.id);
    } catch (e) {
      error = cleanErrorMessage(e);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تعيين ${user.name} كمشرف'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _assignTeacher(BuildContext context) async {
    String? error;
    try {
      await context.read<ApiDataService>().assignTeacherRole(user.id);
      error = null;
    } catch (e) {
      error = cleanErrorMessage(e);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تعيين ${user.name} كأستاذ'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _assignStudent(BuildContext context) async {
    String? error;
    try {
      await context.read<ApiDataService>().assignStudentRole(user.id);
      error = null;
    } catch (e) {
      error = cleanErrorMessage(e);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تعيين ${user.name} كطالب'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.icon(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.readex(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showResetPasswordDialog(BuildContext context, UserModel user) {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  var isBusy = false;

  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('إعادة تعيين كلمة مرور ${user.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم تسجيل خروج هذا الحساب من جميع الأجهزة فور تعيين كلمة المرور الجديدة.',
                  style: AppFonts.readex(
                    fontSize: 12.5,
                    color: AppColors.textSecondary(ctx),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: passwordController,
                  labelText: 'كلمة المرور الجديدة',
                  enabled: !isBusy,
                  validator: (v) =>
                      (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 8),
                PasswordTextField(
                  controller: confirmController,
                  labelText: 'تأكيد كلمة المرور',
                  enabled: !isBusy,
                  validator: (v) => v != passwordController.text
                      ? 'كلمات المرور غير متطابقة'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isBusy ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isBusy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isBusy = true);
                      final error = await ctx
                          .read<ApiDataService>()
                          .resetUserPassword(
                            userId: user.id,
                            newPassword: passwordController.text,
                          );
                      if (!ctx.mounted) return;
                      if (error != null) {
                        setState(() => isBusy = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إعادة تعيين كلمة المرور بنجاح'),
                        ),
                      );
                    },
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('تعيين'),
            ),
          ],
        );
      },
    ),
  );
}
